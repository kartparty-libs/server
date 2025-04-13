<?php
namespace Home\Controller;

use Think\Controller;

class ActivityRelationController extends Controller
{
    public function saveActivity(){
        checkSession();
        $activityRelation = D("ActivityRelation");
        if(!$activityRelation -> create(I("post."),1)){
            $this->ajaxReturn($activityRelation->getError());
        }else{
            $params = I("post.");
            $date = array();
            foreach($params as $key => $value){
                if(strpos($key,"-")>0){
                    $arr = split("-",$key);
                    if(is_numeric($value)){
                        $value = intval($value);
                    }
                    $date[$arr[0]][$arr[1]] = $value;
                }
            }
            foreach($date as $key => $value){
                $activityRelation -> $key = json_encode($value,true);
            }
            $str = explode("_",I("post.activity"));
            $activityRelation->name = $str[0];
            $activityRelation->activity_id = $str[1];
            if($activityRelation->add()){
                save_operate_log("saveActivityConfig", json_encode(I("post."),JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE));
                $this->ajaxReturn(1);
            }else{
                $this->ajaxReturn(0);
            }

        }
    }

    public function getActivitiesByGoodId($id)
    {
        checkSession();
        $activityRelation = D("ActivityRelation");
        $relation = $activityRelation->where("good_id=".$id)->order("id desc")->select();
        $this->ajaxReturn($relation);
    }

    public function getRelationById($id)
    {
        checkSession();
        $activityRelation = D("ActivityRelation");
        $relation = $activityRelation->find($id);
        $this->ajaxReturn($relation);
    }
    public function updateActivity(){
        checkSession();
        $activityRelation = D("ActivityRelation");
        $activityRelation -> create();
        $params = I("post.");
        $date = array();
        foreach($params as $key => $value){
            if(strpos($key,"-")>0){
                $arr = split("-",$key);
                if(is_numeric($value)){
                    $value = intval($value);
                }
                $date[$arr[0]][$arr[1]] = $value;
            }
        }
        foreach($date as $key => $value){
            $activityRelation -> $key = json_encode($value,true);
        }
        $str = explode("_",I("post.activity"));
        $activityRelation->name = $str[0];
        $activityRelation->activity_id = $str[1];
        $activityRelation->where("id=".I("post.id"))->save();
        save_operate_log("updateActivityConfig", json_encode(I("post."),JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn(1);
    }
    public function delRelation($relationId){
        checkSession();
        $activityRelation = D("ActivityRelation");
        $activityRelation->delete($relationId);
        save_operate_log("delActivityConfig", "ActivityConfig Id:".$relationId);
        $this->ajaxReturn(1);
    }

    public function editActivityTime(){
        $activityRelation = D("ActivityRelation");
        $params = I("post.");
        $date = array();
        foreach($params as $key => $value){
            if(strpos($key,"-")>0){
                $arr = split("-",$key);
                if(is_numeric($value)){
                    $value = intval($value);
                }
                $date[$arr[0]][$arr[1]] = $value;
            }
        }
        foreach($date as $key => $value){
            $activityRelation -> $key = json_encode($value,true);
        }
        $id = I("post.id");
        $activityRelation->where("good_id=".$id)->save();
    }
}
