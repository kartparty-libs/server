<?php
namespace Home\Model;

use \Think\Model;

class ActivityItemsModel extends Model
{
    protected $_validate = array(
        array('name','require','活动配置名字必须填写！'),
    );
    public function saveActivityItems($name,$params){

    }
    public function delActivityItems($activityId,$itemId){
        $activityItem = $this->find($itemId);

        $activityAward = M("ActivityAwards");
        $activityAward->delete($activityItem["rewards"]);

        $this -> delete($itemId);

        $activities = M("Activities");
        $activity = $activities->find($activityId);
        $itemsStr = $activity["items"];
        $itemsArr = explode(",",$itemsStr);
        $index = array_search($itemId,$itemsArr);
        if(!empty($index) || $index == 0){
            unset($itemsArr[$index]);
        }
        $itemsStr = implode(",",$itemsArr);
        $activities -> items = $itemsStr;
        $activities -> where('id='.$activityId)->save();
        save_operate_log("delActivityItems", "ActivityItem Id:".$itemId);
    }
    public function updateActivityItems($params){
        $paramArr = array();
        foreach($params as $key => $value){
            if(strpos($key,"-")>0){
                $arr = explode("-",$key);
                if(count($arr)>2){
                    $paramArr[$arr[2]] = intval($value);
                    $typeKey = $arr[1];
                }else{
                    $typeKey = "default";
                    $paramArr[$arr[1]] = intval($value);
                }
            }
        }
        $this -> id = $params["activity_item_id"];
        $this -> key = $params["key"];
        $this -> name = $params["name"];
        $this -> category = $typeKey;
        $this -> params = json_encode($paramArr,true);
        $this -> save();

        $activityItemIds = $this->where("activity_id=".$params["activityId"])->order("key")->field("id")->select();
        for($i = 0;$i<count($activityItemIds);$i++){
            $activityItemIds[$i] = $activityItemIds[$i]["id"];
        }
        $activity = D("Activities");
        $activity->items = implode(",",$activityItemIds);
        $activity->where("id=".$params["activityId"])->save();

        save_operate_log("updateActivityItems", json_encode($params,JSON_UNESCAPED_UNICODE));
    }
}