<?php
namespace Home\Controller;

use Think\Controller;

class ActivityItemsController extends Controller
{

    public function getItemsByActivityId($id)
    {
        checkSession();
        $activities = D("Activities");
        $activity = $activities->find($id);

        $activityItems = D("ActivityItems");
        $map["id"] = array("in",$activity["items"]);
        $activityItemList = $activityItems->where($map)->order('`key`')->select();
        $this->ajaxReturn($activityItemList);
    }

    public function saveActivityItems(){
        checkSession();
        $paramArr = array();
        foreach(I("post.") as $key => $value){
            $typeKey = "default";
            if(strpos($key,"-")>0){
                $arr = explode("-",$key);
                if(count($arr)>2){
                    $typeKey = $arr[1];
                    $paramArr[$arr[2]] = intval($value);
                }else{
                    $paramArr[$arr[1]] = intval($value);
                    if (strval($paramArr[$arr[1]]) != $value) {
                        $paramArr[$arr[1]] = strval($value);
                    }
                }
            }
        }
        if(I("post.category") == "bought_all_gift"){
            $typeKey = I("post.category");
            $paramArr = new \stdClass();
        }
        $activityId = I("post.activity_id");

        $activityItems = M("ActivityItems");
        $activityItems -> key = I("post.key");
        $activityItems -> activity_id = $activityId;
        $activityItems -> name = I("post.name");
        $activityItems -> category = $typeKey;
        $activityItems -> params = json_encode($paramArr,true);
        $id = $activityItems->add();
        if($id){
            save_operate_log("saveActivityItems", json_encode(I("post."),JSON_UNESCAPED_UNICODE));
            $activities = D("Activities");
                $activity = $activities->find($activityId);
            $itemsStr = $activity["items"];
            if($itemsStr==null){
                $itemsStr = $id;
            }else{
                $itemsStr .= ",".$id;
            }
            $activities -> items = $itemsStr;
            $activities -> where('id='.$activityId)->save();
            $this->ajaxReturn(I("post.activity_id"));
        }else{
            $this->ajaxReturn(0);
        }
    }

    public function delActivityItem($activityId,$itemId){
        checkSession();
        $activityItems = D("ActivityItems");
        $activityItems->delActivityItems($activityId,$itemId);
        $this->ajaxReturn($itemId);
    }


    public function getItemById($itemId){
        checkSession();
        $activityItems = D("ActivityItems");
        $item = $activityItems->find($itemId);
        $this->ajaxReturn($item);
    }

    public function updateItems(){
        checkSession();
        /*$activityItems = D("ActivityItems");
        $activityItems->updateActivityItems(I("post."));*/

        $activityItems = M("ActivityItems");
        $paramArr = array();
        foreach(I("post.") as $key => $value){
            if(strpos($key,"-")>0){
                $arr = explode("-",$key);
                if(count($arr)>2){
                    $paramArr[$arr[2]] = intval($value);
                    $typeKey = $arr[1];
                }else{
                    $typeKey = "default";
                    $paramArr[$arr[1]] = intval($value);
                    if (strval($paramArr[$arr[1]]) != $value) {
                        $paramArr[$arr[1]] = strval($value);
                    }
                }
            }
        }
        $activityItems -> id = I("post.activity_item_id");
        $activityItems -> key = I("post.key");
        $activityItems -> name = I("post.name");
        $activityItems -> category = $typeKey;
        $activityItems -> params = json_encode($paramArr,true);
        $activityItems -> save();

        $activityItemIds = $activityItems->where("activity_id=".I("post.activityId"))->order("key")->field("id")->select();
        for($i = 0;$i<count($activityItemIds);$i++){
            $activityItemIds[$i] = $activityItemIds[$i]["id"];
        }
        $activity = D("Activities");
        $activity->items = implode(",",$activityItemIds);
        $activity->where("id=".I("post.activityId"))->save();
        save_operate_log("updateActivityItems", json_encode(I("post."),JSON_UNESCAPED_UNICODE));

        $this->ajaxReturn(I("post.activity_id"));
    }

}
