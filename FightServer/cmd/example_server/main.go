package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/byebyebruce/lockstepserver/cmd/example_server/api"
	"github.com/byebyebruce/lockstepserver/pkg/log4gox"
	"github.com/byebyebruce/lockstepserver/server"

	l4g "github.com/alecthomas/log4go"
)

var (
	httpAddress = flag.String("web", ":80", "web listen address")
	udpAddress  *string
	debugLog    = flag.Bool("log", true, "debug log")
)

type Config struct {
	GameServer  GameServerConfig  `json:"gameServer"`
	FightServer FightServerConfig `json:"fightServer"`
}

type GameServerConfig struct {
	Host string `json:"host"`
	Port int    `json:"port"`
}

type FightServerConfig struct {
	Host string `json:"host"`
	Port string `json:"port"`
}

func main() {
	flag.Parse()
	l4g.Close()
	l4g.AddFilter("debug logger", l4g.DEBUG, log4gox.NewColorConsoleLogWriter())
	configFile := "ServerConfig.json"
	config, err := LoadConfig(configFile)
	if err != nil {
		fmt.Printf("Error loading config file: %v\n", err)
		os.Exit(1)
	}
	FightServerHost := config.FightServer.Host + ":" + config.FightServer.Port
	FightServerPort := ":" + config.FightServer.Port
	udpAddress = flag.String("udp", FightServerPort, "udp listen address("+"'"+FightServerPort+"'"+" "+"means"+" "+FightServerHost+")")
	s, err := server.New(*udpAddress)
	if err != nil {
		panic(err)
	}

	// _ = api.NewWebAPI(*httpAddress, s.RoomManager())
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP, os.Interrupt)
	ticker := time.NewTimer(time.Minute)
	defer ticker.Stop()

	api.TcpClientCreat(s.RoomManager(), config.GameServer.Host, config.GameServer.Port)

	l4g.Info("[main] start...")
	// 主循环
QUIT:
	for {
		select {
		case sig := <-sigs:
			l4g.Info("Signal: %s", sig.String())
			break QUIT
		case <-ticker.C:
			// todo
			fmt.Println("room number ", s.RoomManager().RoomNum())
		}
	}
	l4g.Info("[main] quiting...")
	s.Stop()
}

func LoadConfig(configFile string) (*Config, error) {
	file, err := os.Open(configFile)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	bytes, err := ioutil.ReadAll(file)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := json.Unmarshal(bytes, &config); err != nil {
		return nil, err
	}

	return &config, nil
}
