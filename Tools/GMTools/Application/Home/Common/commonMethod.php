<?php
/**
 * 记录后台用户操作日志
 * @param $operate 操作范围
 * @param $operateValue 操作值
 */
function save_operate_log($operate, $operateValue)
{
    $Operate = M("OperateLog");
    $data["operate_user"] = $_SESSION[C("SESSION_PREFIX")]["user"]["user_name"];
    $data["operate"] = $operate;
    $data["operate_value"] = $operateValue;
    $data["operate_time"] = date("Y-m-d H:i:s");
    $Operate->add($data);
}

/**
 * 表名转换为实体名
 * @param $tableName 表名
 * @return string 实体名
 */
function parseTableNameToModelName($tableName)
{
    $strArr = explode("_", $tableName);
    $modelName = "";
    foreach ($strArr as $word) {
        $modelName = $modelName . ucfirst($word);
    }
    return $modelName;
}

/**
 * 验证页面传递参数
 * @param $str 字符串格式roleId|rolename
 * @return array serverid+roleid或rolename
 */
function createParams($str)
{
    $strArr = preg_split("/[|]+/", $str);
    $params = array();
    $params["serverid"] = intval($_SESSION[C("SESSION_PREFIX")]["serverid"]);
    if (!empty($strArr[0])) {
        $params["roleid"] = $strArr[0];
    } else if (!empty($strArr[0])) {
        $params["rolename"] = $strArr[1];
    }
    return $params;
}

/**
 * 统一分页查询方法
 *
 * @param $modelName 查询实体名以及页面遍历集合名
 * @param $page 查询页数
 */
function createPageResult($modelName, $page,$where)
{
    $Model = D($modelName);
    $count = $Model->where($where)->count();
    $pageCount = ceil($count / C("PAGE_PIECE_NUM"));
    $page = $page < 1 ? 1 : $page;
    $page = $page > $pageCount ? $pageCount : $page;
    $result[$modelName] = $Model->where($where)->limit(($page - 1) * C("PAGE_PIECE_NUM"), C("PAGE_PIECE_NUM"))->order("id desc")->select();
    $result["page"] = $page;
    $result["pageCount"] = $pageCount;
    return $result;
}