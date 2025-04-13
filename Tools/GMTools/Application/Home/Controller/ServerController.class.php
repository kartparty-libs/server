<?php
namespace Home\Controller;

use Think\Controller;
use Think\Log;

class ServerController extends Controller
{
    public function show()
    {
        checkSession();
        $this->assign("platform",C("PLATFORM_URL"));
        $this->display("serverInfo");
    }

    /**
     * 访问服务器修改状态页面
     */
    public function serverState()
    {
        checkSession();
        $this->assign("platform",C("PLATFORM_URL"));
        $this->display("serverState");
    }
    /**
     * 服务器操作
     * @param $serverId 服务器ID
     */
    public function manageServer($serverId,$manage)
    {
        checkSession();
        if(strpos($serverId,",") > 0){
            $serverId = substr($serverId,0,strlen($serverId)-1);
            $serverId = explode(",",$serverId);
        }else if($serverId == 0){
            $serverId = array();
        }else{
	    	$serverId = array($serverId);
		}
        $params = array('serverid' => $serverId);
        $result = phpPostData($manage,$params);
        save_operate_log($manage, json_encode($params));
        $this->ajaxReturn($result);
    }

    /**
     * 刷新服务器列表
     */
    public function refreshServer($serverId)
    {
        checkSession();
        //session("plat",$plat);
        $params = array('serverid' => $serverId);
        $result = phpPostData("listserver",$params);
        
        //$result = postData('http://10.12.253.2:10000/' . "listserver", json_encode($params));
        foreach ($result["list"] as $key => $row) {
            $id[$key] = $row["id"];
            $ip[$key] = $row["ip"];
            $subid[$key] = $row["subid"];
            $param["serverid"] = intval($row["id"]);
            $param["subid"] = intval($row["subid"]);
            $serverInfo = phpPostData("getserverinfo",$param);
            $result["list"][$key]["day"] = $serverInfo["info"]["openday"];
            $result["list"][$key]["time"] = $serverInfo["info"]["opentime"];
            $result["list"][$key]["playernum"] = $serverInfo["info"]["playernum"];            
        }
        array_multisort($id, SORT_ASC, $ip, SORT_DESC, $result["list"]);
        session("serverList", $result["list"]);
        $this->ajaxReturn($result);
    }

   /**
     * 刷新服务器列表
     */
    public function refreshServerState($serverId)
    {
        checkSession();
        $dbInfo = getServerListAddrs();
        $mysql_addr =  $dbInfo["DBAddr"];
        $mysql_usr =  $dbInfo["DBUser"];
        $mysql_pw = $dbInfo["DBPwd"];
        $mysql_name = $dbInfo["DBName"];
        $con = mysql_connect($mysql_addr, $mysql_usr, $mysql_pw);
        if (!$con)
        {
            die('can ont connet'.mysql_error());
        };
        mysql_select_db($mysql_name, $con);
        $result = mysql_query("SELECT * FROM serverlist");
        $indx = 0;
        while($row = mysql_fetch_array($result)){
            foreach( $row as $k=>$v ){
                $serverInfo[$indx][$k] = $v;
            }
            $indx++;
        }
        $this->ajaxReturn($serverInfo);
        mysql_close($con);
    }
   /**
     * 修改服务器状态
     */
    public function SetServerState($serverId,$pf,$status)
    {
        checkSession();
        $dbInfo = getServerListAddrs();
        $mysql_addr =  $dbInfo["DBAddr"];
        $mysql_usr =  $dbInfo["DBUser"];
        $mysql_pw = $dbInfo["DBPwd"];
        $mysql_name = $dbInfo["DBName"];
        $con = mysql_connect($mysql_addr, $mysql_usr, $mysql_pw);
        if (!$con)
        {
            die('can ont connet'.mysql_error());
        };
        mysql_select_db($mysql_name, $con);
        $result = mysql_query("UPDATE serverlist SET status = $status WHERE serverid = $serverId AND pf = $pf");
        $this->ajaxReturn($result);
        mysql_close($con);
    }
/**
     * 刷新服务公告列表
     */
    public function refreshServerNotice($serverId)
    {
        checkSession();
        $dbInfo = getServerListAddrs();
        $mysql_addr =  $dbInfo["DBAddr"];
        $mysql_usr =  $dbInfo["DBUser"];
        $mysql_pw = $dbInfo["DBPwd"];
        $mysql_name = $dbInfo["DBName"];
        $con = mysql_connect($mysql_addr, $mysql_usr, $mysql_pw);
        if (!$con)
        {
            die('can ont connet'.mysql_error());
        };
        
        mysql_select_db($mysql_name, $con);
        mysql_query("SET NAMES 'UTF8'");
        $result = mysql_query("SELECT * FROM notice_info");
        $indx = 0;
        while($row = mysql_fetch_array($result)){
            foreach( $row as $k=>$v ){
                $serverInfo[$indx][$k] = $v;
            }
            $indx++;
        }
        $this->ajaxReturn($serverInfo);
        mysql_close($con);
    }
   /**
     * 修改服务器公告
     */
    public function SetServerNotice($serverId, $str, $newVersion )
    {
        checkSession();
        $dbInfo = getServerListAddrs();
        $mysql_addr =  $dbInfo["DBAddr"];
        $mysql_usr =  $dbInfo["DBUser"];
        $mysql_pw = $dbInfo["DBPwd"];
        $mysql_name = $dbInfo["DBName"];
        $con = mysql_connect($mysql_addr, $mysql_usr, $mysql_pw);
        if (!$con)
        {
            die('can ont connet'.mysql_error());
        };
        mysql_select_db($mysql_name, $con);
        mysql_query("SET NAMES 'UTF8'");
        $result = mysql_query("INSERT INTO notice_info (id,version,text) VALUES ($serverId, $newVersion, '$str')");
        if(!$result){
            $result = mysql_query("UPDATE notice_info SET text = '$str', version = $newVersion WHERE id = $serverId ");
        }
        $this->ajaxReturn($result);
        mysql_close($con);
    }

   /**
     * 服务器热更新
     */
    public function HotUpDataServer($filename )
    {
        checkSession();
        $params["serverid"] = intval($_SESSION[C("SESSION_PREFIX")]["serverid"]);
        $params["filename"] = $filename;
        $result = phpPostData("redofile",$params);
        $result["serverid"] = $params["serverid"];
        $this->ajaxReturn($result);
    }
    
    public function onlineUser($serverId){
        $params["serverid"] = intval($serverId);
        //session("plat",$plat);
        $result = phpPostData("getcurplayernum",$params);
        $this->ajaxReturn($result);
    }
    public function getServerInfo($serverId){
        $params["serverid"] = intval($serverId);
        //session("plat",$plat);
        $result = phpPostData("getserverinfo",$params);
        $this->ajaxReturn($result);
    }
    public function setOpenTime($serverId, $openTime){
        checkSession();
        $params["cmd"]["time"] = strtotime($openTime);
        $params["target"]["server_id"] = $serverId;
        //$params = array('serverid' => $serverId,'ts' => strtotime($openTime));
        $result = phpPostData("set_server_time",$params);
        save_operate_log("setopentime", json_encode($params));
        $this->ajaxReturn($result);
    }
    /*public function getServerInfo(){
        session("plat",I("post.plat"));
        $params = array('serverid' => 0);
        $result = phpPostData("listserver",$params);
        foreach ($result["list"] as $key => $row) {
            $id[$key] = $row["id"];
            $ip[$key] = $row["ip"];
        }
        array_multisort($id, SORT_ASC, $ip, SORT_DESC, $result["list"]);
        $this->ajaxReturn($result);
    }*/
}
