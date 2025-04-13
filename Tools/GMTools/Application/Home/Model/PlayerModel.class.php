<?php
namespace Home\Model;

use \Think\Model;

class PlayerModel extends Model
{
    /**
     * 查询在线人数数据
     * @return mixed
     */
    function getOnlinePlayer()
    {
        $model = new Model();
        $result = $model->query("select * from logdb88.onlinedate_log where FROM_UNIXTIME(recordtime,'%Y-%m-%d %T') >= '2016-03-16' and usernum != 0 limit 72");
        $dataType = "[";
        $data = "[";
        for ($i = 0; $i < count($result); $i++) {
            $dataType .= "'" . date("Y-m-d H:i:s", $result[$i]["recordtime"]) . "',";
            $data .= $result[$i]["usernum"] . ",";
        }
        $result["data"] = substr($data, 0, strlen($data)) . "]";
        $result["dataType"] = substr($dataType, 0, strlen($dataType)) . "]";
        return $result;
    }

    /**
     * 访问玩家日志页面时获取数据库表名及表描述
     * @return mixed
     */
    function initUserLogPage()
    {
        $model = new Model();
        $result = $model->query("select table_name as tableName,table_comment as tableDesc from information_schema.tables where table_schema = 'logdb_game'");// . $_SESSION[C("SESSION_PREFIX")]["serverid"] . "'");
        session("pageNum", 0);
        return $result;
    }

    /**
     * 创建发送邮件Post参数
     * @param $roleId
     * @param $title
     * @param $content
     * @param $item
     * @param $num
     * @return array
     */
    function createSendMailParams($roleId, $title, $content, $item, $num)
    {
        $params = array("serverid" => intval($_SESSION[C("SESSION_PREFIX")]["serverid"]), "roleids" => array($roleId), "title" => $title, "content" => $content);
        $items = array();
        if(!empty($item)){
            $itemArr = preg_split("/[,]+/", $item);
            $numArr = preg_split("/[,]+/", $num);
            if ($item >= 1 && $num >= 1) {
                for ($i = 0; $i < count($itemArr); $i++) {
                    if (!empty($itemArr[$i])) {
                        $items[$i]["itemid"] = intval($itemArr[$i]);
                        $items[$i]["itemnum"] = intval($numArr[$i]);
                    }
                }
            }
        }
        $params["items"] = $items;
        return $params;
    }
}