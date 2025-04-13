<?php
namespace Home\Controller;

use Think\Controller;

class TypeFieldController extends Controller
{
    public function show(){
        $activityType = D("ActivityType");
        $activityTypes = $activityType->order("activity_id")->select();
        $this->assign("activityType",$activityTypes);
        $this->display("typeFieldIndex");
    }

    public  function getFieldByTypeId($id,$activityId){
        checkSession();
        $activityTypeField = D("ActivityTypeField");
        $fields = $activityTypeField->where("activity_type=".$id)->select();
        $result["activityType"] = $fields;

        $activityItem = D("ActivityItems");
        $map["activity_id"] = $activityId;
        $activityItemList = $activityItem -> where($map) -> order("`key`")->select();
        $result["activityItems"] = $activityItemList;
        $result["item"] = session("enum");
        $this->ajaxReturn($result);
    }
    public function getFiledByType($activityType,$type){
        checkSession();
        $activityTypeField = D("ActivityTypeField");
        $map["activity_type"] = $activityType;
        $map["type_key"] = $type;
        $result["fields"] = $activityTypeField->where($map)->select();
        $result["item"] = session("enum");
        $this->ajaxReturn($result);
    }
    public function getTypeKey($activityType){
        checkSession();
        $activityTypeField = D("ActivityTypeField");
        $typeKey = $activityTypeField->distinct(true)->where("activity_type=".$activityType)->order("id desc")->getField("type_key",true);
        $this->ajaxReturn($typeKey);
    }
    public function getFieldsByType($type){
        checkSession();
        $activityTypeField = D("ActivityTypeField");
        $result = $activityTypeField->where("activity_type=".$type)->select();
        $this->ajaxReturn($result);
    }
    public function saveTypeField(){
        checkSession();
        $activityTypeField = D("ActivityTypeField");
        $activityTypeField->create($_POST,1);
        if(empty($_POST["type_key"])){
            $activityTypeField->type_key = "default";
        }
        if(empty($_POST["key_name"])){
            $activityTypeField->key_name = "默认";
        }
        if(empty($_POST["key_order"])){
            $activityTypeField->key_order = "1";
        }
        if($activityTypeField->add()){
            $this->ajaxReturn(1);
        }else{
            $this->ajaxReturn(0);
        }
    }
    public function delTypeField($id){
        checkSession();
        $activityTypeField = D("ActivityTypeField");
        $result = $activityTypeField->delete($id);
        if($result){
            $this->ajaxReturn(1);
        }else{
            $this->ajaxReturn(0);
        }
    }
    public function getTypeField($id){
        checkSession();
        $activityTypeField = D("ActivityTypeField");
        $typeField = $activityTypeField->find($id);
        if(!empty($typeField)){
            $result["ret"] = 1;
            $result["result"] = $typeField;
        }else{
            $result["ret"] = 0;
        }
        $this->ajaxReturn($result);
    }

    public function updateTypeField(){
        checkSession();
        $activityTypeField = D("ActivityTypeField");
        $activityTypeField->create($_POST,2);
        if($activityTypeField->save()){
            $this->ajaxReturn(1);
        }else{
            $this->ajaxReturn(0);
        }
    }
    /**
     * 渠道配置URL
     */
    public function channelUrlPage(){
        checkSession();
        $channelUrl = D("ChannelUrl");
        $result = $channelUrl->select();
        $this->assign("channel",$result);
        $this->display("channelUrl");
    }

    public function saveChannel(){
        checkSession();
        $channelUrl = D("ChannelUrl");
        $channelUrl->create($_POST,1);
        if($channelUrl->add()){
            changeChannelUrl();
            $this->ajaxReturn(1);
        }else{
            $this->ajaxReturn(0);
        }
    }
    public function updateChannel(){
        checkSession();
        $channelUrl = D("ChannelUrl");
        $channelUrl->create($_POST,2);
        if($channelUrl->save()){
            changeChannelUrl();
            $this->ajaxReturn(1);
        }else{
            $this->ajaxReturn(0);
        }
    }
    public function getChannelById($id){
        $channelUrl = D("ChannelUrl");
        $result = $channelUrl->find($id);
        $this->ajaxReturn($result);
    }
    public function delChannel($id){
        $channelUrl = D("ChannelUrl");
        $channelUrl->delete($id);
        changeChannelUrl();
        $this->ajaxReturn(1);
    }
}
