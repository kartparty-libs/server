<?php
/**
 * User: huhaoran
 * Date: 16-3-11
 * Time: 下午15:06
 * To change this template use File | Settings | File Templates.
 */
/**
 * 判断用户是否登录
 */
function checkSession()
{
    if (empty($_SESSION[C("SESSION_PREFIX")]["user"])) {
        redirect(U('Index/Index'));
        exit;
    }
    if (empty($_SESSION[C("SESSION_PREFIX")]["serverid"])) {
        session("serverid", 0);
    }
    if(empty($_SESSION[C("SESSION_PREFIX")]["enum"])){
        $items = D("Items");
        $itemList = $items->select();
        for($i = 0; $i < count($itemList);$i++){
            $itemArr[$itemList[$i]["itemid"]] = $itemList[$i]["itemname"];
        }
        session("enum", json_encode($itemArr));
    }
    //unset($_SESSION[C("SESSION_PREFIX")]["gm_url"]);
    // if(empty($_SESSION[C("SESSION_PREFIX")]["gm_url"])){
        changeChannelUrl();
    // }

    // if(empty($_SESSION[C("SESSION_PREFIX")]["gm_activ_url"])){
        changOtherUrl();
    // }
}

function changeChannelUrl(){
//    $channelUrl = D("ChannelUrl");
//    $url = $channelUrl->select();
//    for($i = 0; $i < count($url);$i++){
//        $urlArr[$url[$i]["name"]] = $url[$i]["gm_url"];
//    }
    foreach( C("PLATFORM_URL") as $k=>$v ){
        $urlArr[$k] = $v;
    }

    session("gm_url", $urlArr);
    
}
function changOtherUrl(){

    foreach( C("PLATFORM_ACTIVI__URL") as $k=>$v ){
        $urlArr[$k] = $v;
    } 
    session("gm_activ_url", $urlArr);

    foreach( C("PLATFORM_PLAYER__URL") as $k=>$v ){
        $urlArr[$k] = $v;
    } 
    session("gm_player_url", $urlArr); 

    foreach( C("PLATFORM_CHARGE__URL") as $k=>$v ){
        $urlArr[$k] = $v;
    } 
    session("gm_charge_url", $urlArr); 

    foreach( C("PLATFORM_LIST__INFO") as $k=>$v ){
        $urlArr[$k] = $v;
    } 
    session("server_list_info", $urlArr);    
    
    foreach( C("PLATFORM_LIST__WANBA") as $k=>$v ){
        $urlArr[$k] = $v;
    } 
    session("server_list_wanba", $urlArr);    
}
/**
 * 跳转到首页
 */ 
function redirectIndex()
{
    session_destroy();
    redirect("index.php");
}

/**
 * @param $name 缓存名字
 * @param $value 缓存内容
 * @param $expire 缓存时间,默认2小时
 */
function saveInMemcache($name, $value, $expire)
{
    if (empty($expire)) {
        $expire = 60 * 60 * 2;
    }
    S($name, $value, array(
            'type' => 'memcache',
            'host' => C('MEMCACHE_IP'),
            'port' => C('MEMCACHE_PORT'),
            'prefix' => C('MEMCACHE_PREFIX'),
            'expire' => $expire)
    );
}

function phpPostData($method,$param,$url_type){
    $data["params"] = $param;
    $data["cmd"] = $method;
    $gm_url = "";
    switch($url_type)
    {
        case 1:
            $gm_url = "gm_player_url";
            break;
        case 2:
            $gm_url = "gm_charge_url";
            break;           
        case 3:
            $gm_url = "gm_activ_url";
            break;
        default:
            $gm_url = "gm_url";
    }
    //  $url = "http://127.0.0.1:10001/receive?inviter =1111&invitee=22222";
    
    $url = $_SESSION[C("SESSION_PREFIX")][$gm_url][$_SESSION[C("SESSION_PREFIX")]["plat"]] . $method;

    return postData($url, json_encode($param));
}
function getServerListAddrs(){
    if($_SESSION[C("SESSION_PREFIX")]["plat"] == "WanBa")
    {
        return $dbinfo = $_SESSION[C("SESSION_PREFIX")]["server_list_wanba"];   
    }
    return $dbinfo = $_SESSION[C("SESSION_PREFIX")]["server_list_info"];
}
include "commonMethod.php";
