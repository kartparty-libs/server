package api

import (
	"bytes"
	"encoding/binary"
	"errors"
	"fmt"
	"net"
	"time"

	"github.com/byebyebruce/lockstepserver/logic"
)

type NetworkManager struct {
	conn                  net.Conn
	timeout               time.Duration
	sequence              byte
	sendQueue             chan NetDataPacket
	receiveQueue          chan NetDataPacket
	isConnected           bool
	lastConnectServerIP   string
	lastConnectServerPort int
}

type NetDataPacket struct {
	length int16
	data   []byte
}

type GameRoomManager struct {
	Manager *logic.RoomManager
}

var network *NetworkManager
var RoomManager *GameRoomManager
var timeFlage int = 5

func NewNetworkManager() *NetworkManager {
	nm := &NetworkManager{
		timeout:      15 * time.Second,
		sendQueue:    make(chan NetDataPacket, 100),
		receiveQueue: make(chan NetDataPacket, 100),
		isConnected:  false,
	}
	return nm
}

func NewGameRoomManager(m *logic.RoomManager) *GameRoomManager {
	rm := &GameRoomManager{
		Manager: m,
	}
	return rm
}

func (nm *NetworkManager) Connect() error {
	fmt.Println("请求连接：", nm.lastConnectServerIP, nm.lastConnectServerPort)
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", nm.lastConnectServerIP, nm.lastConnectServerPort), nm.timeout)
	if err != nil {
		nm.Close()
		return err
	}
	nm.conn = conn
	nm.isConnected = true

	go nm.receiveThread()
	go nm.sendThread()

	_, err = nm.conn.Write([]byte(fmt.Sprintf("tgw_l7_forward\r\nHost:%s:%d\r\n\r\n\x00", nm.lastConnectServerIP, nm.lastConnectServerPort)))
	if err != nil {
		nm.Close()
		return err
	}
	fmt.Println("连接成功：", nm.lastConnectServerIP, nm.lastConnectServerPort)
	// 每隔1秒发送一次心跳包
	CodeService := NewCodeService()
	bufMsg := CodeService.Encode("K_HeartBeat")
	data := bufMsg.Bytes()
	for {
		nm.ProcessReceivedPackets()
		err = nm.Send(data)
		if err != nil {
			fmt.Println("Send error:", err)
			break
		}
		time.Sleep(time.Second)
	}
	return nil
}

func (nm *NetworkManager) receiveThread() {
	defer nm.Close()

	for nm.isConnected {
		head := make([]byte, 2)
		_, err := nm.conn.Read(head)
		if err != nil {
			return
		}

		dataLen := int16(binary.LittleEndian.Uint16(head))
		body := make([]byte, dataLen)
		_, err = nm.conn.Read(body)

		if err != nil {
			return
		}

		nm.receiveQueue <- NetDataPacket{
			length: dataLen,
			data:   body,
		}
	}
}

func (nm *NetworkManager) sendThread() {
	defer nm.Close()
	for nm.isConnected {
		select {
		case packet := <-nm.sendQueue:
			dataLenBytes := make([]byte, 2)
			binary.LittleEndian.PutUint16(dataLenBytes, uint16(packet.length))
			_, err := nm.conn.Write(dataLenBytes)
			if err != nil {
				return
			}
			_, err = nm.conn.Write(packet.data)
			if err != nil {
				return
			}
		}
	}
}

func (nm *NetworkManager) Send(data []byte) error {
	if !nm.isConnected {
		return errors.New("network not connected")
	}
	dataLength := len(data)
	realLen := dataLength + 1
	newData := make([]byte, realLen)
	newData[0] = nm.sequence
	copy(newData[1:], data)
	nm.sendQueue <- NetDataPacket{
		length: int16(realLen),
		data:   newData,
	}
	nm.sequence++

	return nil
}

func (nm *NetworkManager) Close() {
	if nm.conn != nil {
		nm.conn.Close()
	}
	nm.isConnected = false
	for {
		if !nm.isConnected && timeFlage < 0 {
			timeFlage = 5
			network.Connect()
			break
		}
		timeFlage--
		time.Sleep(5 * time.Second)
	}
}

func (nm *NetworkManager) IsConnected() bool {
	return nm.isConnected
}

func (nm *NetworkManager) ProcessReceivedPackets() {
	for len(nm.receiveQueue) > 0 {
		packet := <-nm.receiveQueue
		Msgdata := packet.data
		DCodeService := NewDCodeService()

		dataReader := bytes.NewReader(Msgdata)
		decodeData, err := DCodeService.Decode(dataReader, len(Msgdata))
		// 检查是否有错误
		if err != nil {
			fmt.Println("Error decoding data:", err)
			return
		}
		var FuncName string = decodeData[0].(string)
		fn := CharToFunc(FuncName)
		if fn == nil {
			fmt.Println("Error CharToFunc:", FuncName)
			return
		}
		// 移除第一个元素
		decodeData = decodeData[1:]
		fn(decodeData...)
	}
}

func (nm *NetworkManager) SetTimeout(timeout time.Duration) {
	nm.timeout = timeout
}

func TcpClientCreat(m *logic.RoomManager, serverIP string, serverPort int) {
	RoomManager = NewGameRoomManager(m)
	network = NewNetworkManager()
	network.lastConnectServerIP = serverIP
	network.lastConnectServerPort = serverPort
	network.Connect()

	// return RoomManager
}

func heartBeat() {
	timeFlage = 5
}
func creatGameRoom(nRoomID uint64, tRoleId []uint64) {
	_, err := RoomManager.Manager.CreateRoom(nRoomID, 0, tRoleId, 0, "test")
	if nil != err {
		fmt.Println("Error creatGameRoom :", err)
	} else {
		CodeService := NewCodeService()
		bufMsg := CodeService.Encode("K_CreatGameSuccess", int(nRoomID))
		data := bufMsg.Bytes()
		network.Send(data)
	}
}

func destroyGameRoom(nRoomID uint64) {
	room := RoomManager.Manager.GetRoom(nRoomID)
	if nil == room {
		fmt.Println("Error destroyGameRoom GetRoom :", nRoomID)
	} else {
		room.SetGameOver()
		CodeService := NewCodeService()
		bufMsg := CodeService.Encode("K_DestroyRoomSuccess", int(nRoomID))
		data := bufMsg.Bytes()
		network.Send(data)
	}
}

//定义接受的服务器消息
//------------------------------------------------------------------------------------
// CharToFunc 接受一个字符串参数并返回一个对应的函数
func CharToFunc(char string) func(...interface{}) {
	// 创建一个映射，它将字符串映射到相应的函数
	charMap := map[string]func(...interface{}){
		"F_Test":            F_Test,
		"F_HeartBeat":       F_HeartBeat,
		"F_CreatGameRoom":   F_CreatGameRoom,
		"F_DestroyGameRoom": F_DestroyGameRoom,
	}
	// 从映射中获取对应的函数
	fn, ok := charMap[char]
	if !ok {
		return nil
	}
	return fn
}

// F_Test 函数接受可变参数并打印出参数
func F_Test(args ...interface{}) {
	// fmt.Println("args data0:=====", args[0].(float64))
	// fmt.Println("args data1:=====", args[1].(bool))
	// fmt.Println("args data2:=====", args[2].(map[interface{}]interface{}))
	// fmt.Println("args data3:=====", args[3].(map[interface{}]interface{}))
}

//心跳包收
func F_HeartBeat(args ...interface{}) {
	heartBeat()
}

//创建游戏房间
func F_CreatGameRoom(args ...interface{}) {
	nRoomID := args[0].(float64)
	tRoleId := MapToArray(args[1].(map[interface{}]interface{}))
	creatGameRoom(uint64(nRoomID), tRoleId)
}

//游戏房间战斗结束
func F_DestroyGameRoom(args ...interface{}) {
	nRoomID := args[0].(float64)
	destroyGameRoom(uint64(nRoomID))
}
