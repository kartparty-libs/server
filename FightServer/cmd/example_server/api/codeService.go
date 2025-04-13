package api

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"math"
	"reflect"
)

type CodeService struct {
	args               []interface{}
	nIndex             int
	enByte             *bytes.Buffer
	nUse               int
	oData              []interface{}
	key                interface{}
	tables             []interface{}
	nMaxSendBufferSize int
}

func NewCodeService() *CodeService {
	return &CodeService{
		nIndex:             0,
		enByte:             new(bytes.Buffer),
		nUse:               0,
		oData:              make([]interface{}, 0),
		key:                nil,
		tables:             make([]interface{}, 0),
		nMaxSendBufferSize: 4094,
	}
}

func (cs *CodeService) GetMaxSendBufferSize() int {
	return cs.nMaxSendBufferSize
}

func (cs *CodeService) Encode(args ...interface{}) *bytes.Buffer {
	cs.enByte.Reset()
	cs.enByte.Grow(cs.nMaxSendBufferSize)
	cs.args = args
	cs.nIndex = 0

	for cs.excuteEncode(cs.args[cs.nIndex]) {
		cs.nIndex++
		if cs.nIndex == len(cs.args) {
			break
		}
	}

	return cs.enByte
}

func (cs *CodeService) excuteEncode(data interface{}) bool {
	if data == nil {
		cs.enByte.WriteByte(0)
	} else {
		switch v := data.(type) {
		case bool:
			if v {
				cs.enByte.WriteByte(1)
			} else {
				cs.enByte.WriteByte(2)
			}
		case int:
			// 小于一个字节的数
			if data.(int)%1 == 0 && data.(int) == (data.(int)<<58>>58) {
				cs.enByte.WriteByte(64 | (byte(data.(int)) & 0x3F))
			} else if data.(int)%1 == 0 && data.(int) > -32768 && data.(int) < 32767 {
				cs.enByte.WriteByte(5)
				binary.Write(cs.enByte, binary.LittleEndian, int16(data.(int)))
			} else if data.(int)%1 == 0 && data.(int) > -2147483648 && data.(int) < 2417483647 {
				cs.enByte.WriteByte(6)
				binary.Write(cs.enByte, binary.LittleEndian, int32(data.(int)))
			} else {
				cs.enByte.WriteByte(4)
				binary.Write(cs.enByte, binary.LittleEndian, float64(data.(int)))
			}
		case float64:
			cs.enByte.WriteByte(4)
			binary.Write(cs.enByte, binary.LittleEndian, v)
		case string:
			strLen := len(v)
			if strLen < 64 {
				cs.enByte.WriteByte(byte(-128 | strLen))
			} else {
				cs.enByte.WriteByte(9)
				binary.Write(cs.enByte, binary.LittleEndian, int16(strLen))
			}
			cs.enByte.WriteString(v)
		case []interface{}:
			cs.enByte.WriteByte(16)
			cs.enByte.WriteByte(0)
			for idx, value := range v {
				if !cs.excuteEncode(idx + 1) {
					return false
				}
				if !cs.excuteEncode(value) {
					return false
				}
			}
			cs.enByte.WriteByte(0)
		case map[string]interface{}:
			cs.enByte.WriteByte(16)
			cs.enByte.WriteByte(0)
			for prop, value := range v {
				if !cs.excuteEncode(prop) {
					return false
				}
				if !cs.excuteEncode(value) {
					return false
				}
			}
			cs.enByte.WriteByte(0)
		default:
			fmt.Printf("Unsupported data type: %s\n", reflect.TypeOf(data))
			return false
		}
	}
	return true
}

type DCodeService struct {
	nUse   int
	oData  []interface{}
	key    interface{}
	tables []map[interface{}]interface{}
}

func NewDCodeService() *DCodeService {
	return &DCodeService{
		nUse:   0,
		oData:  make([]interface{}, 0),
		key:    nil,
		tables: make([]map[interface{}]interface{}, 0),
	}
}

// Decode decodes the data with the given length and returns the parsed data array.

func (cs *DCodeService) Decode(data *bytes.Reader, length int) ([]interface{}, error) {
	cs.nUse = 0
	cs.oData = make([]interface{}, 0)
	cs.key = nil
	cs.tables = make([]map[interface{}]interface{}, 0)

	for cs.executeDecode(data, length) {
		if cs.nUse >= length {
			break
		}
	}
	return cs.oData, nil
}

// executeDecode processes the decoding of the data.
func (cs *DCodeService) executeDecode(data *bytes.Reader, length int) bool {
	if !cs.query(1, length, false) {
		return false
	}
	flag, _ := data.ReadByte()
	cs.query(1, length, true)

	if flag == 0 {
		cs.oData = append(cs.oData, nil)
	} else if flag == 1 || flag == 2 {
		cs.oData = append(cs.oData, flag == 1)
	} else {
		flag1 := flag & 0xC0
		flag2 := flag & 0xFC

		if flag1 == 128 || flag2 == 8 {
			strLen := 0
			if flag1 == 128 {
				strLen = int(flag & 0x3F)
			} else if flag == 9 {
				if !cs.query(2, length, false) {
					return false
				}
				strLenBytes := make([]byte, 2)
				data.Read(strLenBytes)
				strLen = int(binary.LittleEndian.Uint16(strLenBytes))
				cs.query(2, length, true)
			} else {
				return false
			}

			if !cs.query(strLen, length, false) {
				return false
			}
			strBytes := make([]byte, strLen)
			data.Read(strBytes)
			cs.oData = append(cs.oData, string(strBytes))
			cs.query(strLen, length, true)
		} else if flag1 == 64 || flag2 == 4 {
			var num float64
			if flag1 == 64 {
				num = float64(int32(flag) << 26 >> 26)
			} else if flag == 5 {
				if !cs.query(2, length, false) {
					return false
				}
				numBytes := make([]byte, 2)
				data.Read(numBytes)
				num = float64(int16(binary.LittleEndian.Uint16(numBytes)))
				cs.query(2, length, true)
			} else if flag == 6 {
				if !cs.query(4, length, false) {
					return false
				}
				numBytes := make([]byte, 4)
				data.Read(numBytes)
				num = float64(int32(binary.LittleEndian.Uint32(numBytes)))
				cs.query(4, length, true)
			} else if flag == 7 || flag == 4 {
				if !cs.query(8, length, false) {
					return false
				}
				numBytes := make([]byte, 8)
				data.Read(numBytes)
				// num = float64(binary.LittleEndian.Uint64(numBytes))
				buf := bytes.NewReader(numBytes)
				err := binary.Read(buf, binary.LittleEndian, &num)
				if err != nil {
					fmt.Println("Error converting bytes to float64:", err)
				}
				cs.query(8, length, true)
			} else {
				return false
			}
			cs.oData = append(cs.oData, num)
		} else if flag2 == 16 {
			if flag == 16 {
				if !cs.query(1, length, false) {
					return false
				}
				data.ReadByte()
				cs.query(1, length, true)
				obj := make(map[interface{}]interface{})
				cs.tables = append(cs.tables, obj)
				for {
					if !cs.executeDecodeTable(obj, data, length, true) {
						return false
					}
					if cs.key == nil {
						cs.tables = cs.tables[:len(cs.tables)-1]
						break
					}
					if !cs.executeDecodeTable(obj, data, length, false) {
						return false
					}
				}
				cs.oData = append(cs.oData, obj)
			} else {
				return false
			}
		} else {
			return false
		}
	}
	return true
}

// executeDecodeTable processes the decoding of Lua-Table.
func (cs *DCodeService) executeDecodeTable(o map[interface{}]interface{}, data *bytes.Reader, length int, isKey bool) bool {
	if !cs.query(1, length, false) {
		return false
	}
	flag, _ := data.ReadByte()
	cs.query(1, length, true)
	if flag == 0 {
		if isKey {
			cs.key = nil
		} else {
			o[cs.key] = nil
		}
	} else if flag == 1 || flag == 2 {
		b := flag == 1
		if isKey {
			cs.key = fmt.Sprint(b)
		} else {
			o[cs.key] = b
		}
	} else {
		flag1 := flag & 0xC0
		flag2 := flag & 0xFC

		if flag1 == 128 || flag2 == 8 {
			strLen := 0
			if flag1 == 128 {
				strLen = int(flag & 0x3F)
			} else if flag == 9 {
				if !cs.query(2, length, false) {
					return false
				}
				strLenBytes := make([]byte, 2)
				data.Read(strLenBytes)
				strLen = int(binary.LittleEndian.Uint16(strLenBytes))
				cs.query(2, length, true)
			} else {
				return false
			}

			if !cs.query(strLen, length, false) {
				return false
			}
			strBytes := make([]byte, strLen)
			data.Read(strBytes)
			str := string(strBytes)
			if isKey {
				cs.key = str
			} else {
				o[cs.key] = str
			}
			cs.query(strLen, length, true)
		} else if flag1 == 64 || flag2 == 4 {
			var num float64
			if flag1 == 64 {
				num = float64(int32(flag) << 26 >> 26)
			} else if flag == 5 {
				if !cs.query(2, length, false) {
					return false
				}
				numBytes := make([]byte, 2)
				data.Read(numBytes)
				num = float64(int16(binary.LittleEndian.Uint16(numBytes)))
				cs.query(2, length, true)
			} else if flag == 6 {
				if !cs.query(4, length, false) {
					return false
				}
				numBytes := make([]byte, 4)
				data.Read(numBytes)
				num = float64(int32(binary.LittleEndian.Uint32(numBytes)))
				cs.query(4, length, true)
			} else if flag == 7 || flag == 4 {
				if !cs.query(8, length, false) {
					return false
				}
				numBytes := make([]byte, 8)
				data.Read(numBytes)
				num = math.Float64frombits(binary.LittleEndian.Uint64(numBytes))
				cs.query(8, length, true)
			} else {
				return false
			}
			if isKey {
				cs.key = num
			} else {
				o[cs.key] = num
			}
		} else if flag2 == 16 {
			if flag == 16 {
				if !cs.query(1, length, false) {
					return false
				}
				data.ReadByte()
				cs.query(1, length, true)

				obj := make(map[interface{}]interface{})
				cs.tables[len(cs.tables)-1][cs.key] = obj
				cs.tables = append(cs.tables, obj)
				for {
					if !cs.executeDecodeTable(obj, data, length, true) {
						return false
					}
					if cs.key == nil {
						cs.tables = cs.tables[:len(cs.tables)-1]
						break
					}
					if !cs.executeDecodeTable(obj, data, length, false) {
						return false
					}
				}
			} else {
				return false
			}
		} else {
			return false
		}
	}
	return true
}

// query is a helper function to check if the given number of bytes can be read from the data stream without exceeding the limit.
func (cs *DCodeService) query(num, length int, add bool) bool {
	if !add {
		if cs.nUse+num > length {
			return false
		}
		return true
	} else {
		cs.nUse += num
	}
	return true
}

func MapToArray(mapData map[interface{}]interface{}) []uint64 {
	// 将 map[interface{}]interface{} 转换为 map[float64]float64
	floatMap := make(map[float64]float64)
	for k, v := range mapData {
		if key, ok := k.(float64); ok {
			if value, ok := v.(float64); ok {
				floatMap[key] = value
			}
		}
	}
	// 将 map[float64]float64 转换为 []uint64 切片
	uint64Slice := make([]uint64, len(floatMap))
	i := 0
	for _, v := range floatMap {
		uint64Slice[i] = uint64(v)
		i++
	}
	return uint64Slice
}
