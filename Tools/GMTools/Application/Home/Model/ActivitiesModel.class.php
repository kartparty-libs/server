<?php
namespace Home\Model;

use \Think\Model;

class ActivitiesModel extends Model
{
    protected $_validate = array(
        array('id','require','活动ID必须填写！'),
        array('name','require','活动名字必须填写！'),
    );
    public function activityDel($id){
        $activityItems = D("ActivityItems");
        $itemsIds = $activityItems->where("activity_id=".$id)->getField("id",true);

        $itemsIdsStr = "";
        for($i = 0;$i<count($itemsIds);$i++){
            $itemsIdsStr.= $itemsIds[$i].",";
        }
        $map["content_id"] = array("in",rtrim($itemsIdsStr,","));
        $activityAward = D("ActivityAwards");
        $activityAward->where($map)->delete();
        $activityItems->where("activity_id=".$id)->delete();

        $this->delete($id);
    }
    public function initPage($page,$where){
        $result = createPageResult("Activities",$page,$where);
        $activityType = D("ActivityType");
        $activityTypeList = $activityType->order("activity_id")->select();
        for ($i = 0; $i < count($activityTypeList); $i++) {
            $itemResult[$activityTypeList[$i]["activity_id"]] = $activityTypeList[$i]["activity_name"];
        }
        session("activityTypes",$itemResult);

        $activityPosition = D("ActivityPosition");
        $activityPositionList = $activityPosition->select();
        for ($i = 0; $i < count($activityPositionList); $i++) {
            $position[$activityPositionList[$i]["id"]] = $activityPositionList[$i]["activity_position"];
        }
        session("activityPosition",$position);
        return $result;
    }
}