<?php
namespace Home\Controller;

use Think\Controller;

class ActivityController extends Controller
{
    public function show()
    {
        checkSession();
        $page = intval(I("get.page"));
        $activities = D("Activities");
        $type = I('get.type');
        if(strlen($type) > 0){
            $where["type"] = $type;
            $this->assign("act_type",$type);
        }
        $result = $activities->initPage($page,$where);
        $items = D("Items");
        $this->assign("items",$items->select());
        $this->assign("result",$result);
        $this->display("activitiesManage");
    }

    public function saveActivity(){
        checkSession();
        $activities = D("Activities");
        if(!$activities->create(I('post.'),1)){
            $this->ajaxReturn($activities->getError());
        }else{
            $activities -> create_time = date("Y-m-d H:i:s");
            if($activities -> add()){
                save_operate_log("saveActivity", json_encode(I("post."),JSON_UNESCAPED_UNICODE));
                $this->ajaxReturn(1);
            }else{
                $this->ajaxReturn(0);
            }
        }
    }
    public function ActivityDel($id){
        checkSession();
        $activityRelation = D("ActivityRelation");
        $activityRelation->where("activity_id=".$id)->delete();

        $activity = D("Activities");
        $activity->activityDel($id);
        $this->ajaxReturn(1);
    }

    public function getActivityById($id){
        checkSession();
        $activities = D("Activities");
        $activity = $activities->find($id);
        $this->ajaxReturn($activity);
    }
    public function updateActivity(){
        checkSession();
        $activities = D("Activities");
        $activities->create();
        $activities -> create_time = date("Y-m-d H:i:s");
        $activities->where("id=".I("post.real_act_id"))->save();

        $activityItems = D("ActivityItems");
        $activityItems->activity_id = I("post.id");
        $activityItems->where("activity_id=".I("post.real_act_id"))->save();
        save_operate_log("updateActivity", json_encode(I("post."),JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn(1);
    }


    public function getActivities(){
        checkSession();
        $activities = D("Activities");
        $activity = $activities->getField("id,name");
        $this->ajaxReturn($activity);
    }

}
