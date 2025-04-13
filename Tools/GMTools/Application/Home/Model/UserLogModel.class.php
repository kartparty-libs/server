<?php
namespace Home\Model;

use \Think\Model;

class UserLogModel extends Model
{
    /**
     * 查询玩家游戏日志
     * @param $tableName 日志表
     * @param $roleId 角色ID
     * @param $startTime 开始时间
     * @param $endTime 结束时间
     * @param $page 当前页数
     * @return mixed
     */
    public function getUserLog($db,$tableName, $roleId, $startTime, $endTime, $page)
    {
        $model = new Model();
        //$result["col"] = $model->query("show full columns from logdb" . $_SESSION[C("SESSION_PREFIX")]["serverid"] . "." . $tableName);
        $result["col"] = $model->query("show full columns from ".$db."." . $tableName);
        $data = array();
        if (!empty($roleId)) {
            $data["roleid"] = $roleId;
        }
		if(!empty($startTime)||!empty($endTime)){
			if(!empty($startTime)){
				$data['writetime'][0] = array('egt',strtotime($startTime));
			}
			if(!empty($endTime)){
				$data['writetime'][1] = array('elt',strtotime($endTime));
			}
		}
		
        $tableName = $db.".".$tableName;//"logdb" . $_SESSION[C("SESSION_PREFIX")]["serverid"] . "." . $tableName;
        $result["count"] = $model->table($tableName)->where($data) -> count();
        $result["pageCount"] = ceil($result["count"] / C("PAGE_PIECE_NUM"));
        /*处理当前页数*/
        $page = $page > $result["pageCount"] ? $result["pageCount"] : $page;
        $page = $page < 1 ? 1 : $page;
        $result["result"] = $allResult = $model->table($tableName)->where($data)->limit(C("PAGE_PIECE_NUM"))->page($page) -> select();
		//echo $model->getLastSql();
        $result["page"] = $page;
        return $result;
    }
}