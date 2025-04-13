<?php
namespace Home\Controller;

use Org\Util\Date;
use Think\Controller;
use Think\Model;

class GmManageController extends Controller
{
    public $page = 1;

    /**
     * 访问发送广播页面
     */
    public function noticePage()
    {
        checkSession();
        $this->display("serverNotice");
    }

    /**
     * 发送广播
     * @param $content 广播内容
     */
    public function noticeToServer( $serverid )
    {
        checkSession();
        $params = I("get.");
        $serverid = $serverid != "0" ? intval($_SESSION[C("SESSION_PREFIX")]["serverid"]) : 0 ;
        $params["serverid"] = $serverid;
        $result = phpPostData("notice",$params,1);
        save_operate_log("noticeToServer", json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }

    /**
     * 查询广播
     */
    public function selectNotice()
    {
        checkSession();
        $params["serverid"] = intval($_SESSION[C("SESSION_PREFIX")]["serverid"]);
        $result = phpPostData("selectnotice",$params,1);
        $this->ajaxReturn($result);
    }

    
    public function DelNotice($nNotice)
    {
        checkSession();
        $params["serverid"] = intval($_SESSION[C("SESSION_PREFIX")]["serverid"]);
        $params["nNotice"] = $nNotice;
        $result = phpPostData("delnotice",$params,1);
        $this->ajaxReturn($result);
    }

    /**
     * 查询玩家基本信息
     * @param $str roleId|roleName字符串
     */
    public function getPlayers($str)
    {
        checkSession();
        $strArr = preg_split("/[|]+/", $str);
        $params = array();
        $params["serverid"] = intval($_SESSION[C("SESSION_PREFIX")]["serverid"]);
        if (!empty($strArr[0])) {
            $params["openid"] = $strArr[0];
            $method = "openid2roleinfo";
        } else if (!empty($strArr[1])) {
            $params["rolename"] = $strArr[1];
            $method = "rolename2roleinfo";
        }
        $result = phpPostData($method,$params,1);
        $this->ajaxReturn($result);
    }

    /**
     * 查询玩家信息页面
     */
    public function getPlayerInfo()
    {
        checkSession();
        $this->display("playerInfoPage");
    }
    /**
     * 查询玩家充值信息
     */
    public function chargeInfoPage()
    {
        $item = D("Items");
        $result = $item->select();
        $this->assign("items",$result);
        $this->display("chargeInfoPage");
    } 

    public function playerDetailPage(){
        $item = D("Items");
        $result = $item->select();
        $this->assign("items",$result);
        $this->display("playerDetailPage");
    }

    /**
     * 踢出玩家页面
     */
    public function kickPlayerPage()
    {
        checkSession();
        $this->display("kickPlayerPage");
    }

    /**
     * 踢出玩家
     * @param $str roleId|roleName字符串
     */
    public function kickPlayer($str)
    {
        checkSession();
        $params = createParams($str);
        $result = phpPostData("kickplayer",$params);
        save_operate_log("kickPlayer", json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }

    /**
     * 发送邮件页面
     */
    public function sendMailPage()
    {
        checkSession();
        $item = D("Items");
        $result = $item->select();
        $this->assign("items",$result);
        $this->display("sendMailPage");
    }
    /**
     * 发送邮件
     * @param $title 邮件标题
     * @param $content 邮件内容
     * @param $roleId 玩家ID(roleId为0时发送全服)
     * @param $item 发送道具Id字符串
     * @param $num 发送道具数量字符串
     */
    public function sendMail($title, $content, $item, $num)
    {
        checkSession();
        $player = D("Player");
        $roleId = empty($_GET["roleId"])?"":$_GET["roleId"];
        $params = $player->createSendMailParams($roleId, $title, $content, $item, $num);
        //var_dump(json_encode($params,JSON_UNESCAPED_UNICODE));
        $result = phpPostData("send_mail",$params,1);
        save_operate_log("send_mail", json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }

        /**
     * 发送全服邮件
     * @param $title 邮件标题
     * @param $content 邮件内容
     * @param $roleId 玩家ID
     * @param $item 发送道具Id字符串
     * @param $num 发送道具数量字符串
     */
    public function sendAllMail($title, $content, $item, $num)
    {
        checkSession();
        $player = D("Player");
        $roleId = empty($_GET["roleId"])?"":$_GET["roleId"];
        $params = $player->createSendMailParams($roleId, $title, $content, $item, $num);
        $params["serverid"] = 0;
        //var_dump(json_encode($params,JSON_UNESCAPED_UNICODE));
        $result = phpPostData("send_mail",$params,1);
        save_operate_log("send_mail", json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }

    /**
     * 在线玩家视图页面
     */
    /*public function onlineUser()
    {
        checkSession();
        $result = postData(C("GM_POST_URL") . "getcurplayernum", json_encode(createParams()));
        var_dump($result);
        $this->display();
    }*/

    /**
     * 查询玩家游戏日志页面
     */
    public function userLogPage()
    {
        checkSession();
		$player = D("Player");
        $this->assign("tables", $player->initUserLogPage());
        $this->display();
    }

    /**
     * 分页显示玩家游戏日志
     * @param $logType 日志类型
     * @param $roleId 玩家ID
     * @param $start 开始时间
     * @param $end 结束时间
     * @param $page 当前页数
     */
    public function getUserLog($db,$logType, $roleId, $start, $end, $page)
    {
        checkSession();
        $userLog = D("UserLog");
        $result = $userLog->getUserLog($db,$logType, $roleId, $start, $end, $page);
        $usageType = D("ItemUseageType");
        $usageTypeList = $usageType->select();
        for($i = 0; $i < count($usageTypeList);$i++){
            $usageTypeArr[$usageTypeList[$i]["idx"]] = $usageTypeList[$i]["type_name"];
        }
        $result["usageType"] = $usageTypeArr;
        $this->ajaxReturn($result);
    }

    /**
     * 获取玩家详细信息
     * @param $roleId
     */
    public function getPlayerDetail($roleId)
    {
        checkSession();
        $result = phpPostData("roleid2roleinfo",createParams($roleId),1);
        $this->ajaxReturn($result);
    }

    /**
     * 封号/解封玩家
     * @param $roleId
     * @param $time 封停时间 0即为解封
     */
    public function banPlay($roleId, $time)
    {
        checkSession();
        $params = createParams($roleId);
        $params["sec"] = intval($time) * 60 * 60;
        $result = phpPostData("banplay",$params,1);
        save_operate_log("banplay", json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }
    /**
     * 禁言/解禁玩家
     * @param $roleId
     * @param $time 封停时间 0即为解封
     */
    public function banSpeak($roleId, $time)
    {
        checkSession();
        $params = createParams($roleId);
        $params["sec"] = intval($time) * 60 * 60;
        $result = phpPostData("banspeak",$params,1);
        save_operate_log("banspeak", json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }

    /**
     * 模拟充值
     * @param $roleId
     * @param $chargeid 充值id
     * @param $money 充值钱数
     */
    public function PlayerCharge($roleId, $chargeid,$money,$rolename, $uid, $commonParam)
    {
        checkSession();
        $params = createParams($roleId);
        $params["chargeid"] = $chargeid;
        $params["money"] = $money;
        $params["rolename"] = $rolename;
        $params["uid"] = $uid;
        $params["commonParam"] = $commonParam;
        $params["payType"] = "GM";
        $result = phpPostData("recharge",$params,2);
        // save_operate_log("recharge", json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }

    /**
     * 获取充值记录信息
     * @param $roleId
     */
    public function getChargeInfo($roleId)
    {
        checkSession();
        $params = createParams($roleId);
        $result = phpPostData("get_recharge_info", $params,2);
        $this->ajaxReturn($result);
    }


    public function manageByOpenid($openid,$manage,$sec){
        checkSession();
        $params = array();
        $params["serverid"] = intval($_SESSION[C("SESSION_PREFIX")]["serverid"]);
        $params["openid"] = $openid;
        $params["sec"] = intval($sec) * 60 * 60;
        $result = phpPostData($manage,$params,1);
        save_operate_log($manage, json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }

    public function batchUserInfoPage(){
        checkSession();
        $this->display("batchUserInfo");
    }

    public function getPlayersByName($userNames){
        checkSession();
        $params = array();
        $params["serverid"] = intval($_SESSION[C("SESSION_PREFIX")]["serverid"]);
        $params["rolenames"] = explode(",",$userNames);
        $result = phpPostData("rolenames2roleid",$params,1);
        save_operate_log("s2roleid", json_encode($params,JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn($result);
    }
}

