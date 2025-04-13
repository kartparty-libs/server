<?php
namespace Home\Controller;

use Think\Controller;

class AwardsController extends Controller
{

    public function getRewardByItemId($itemId){
        checkSession();
        $activityAwards = D("ActivityAwards");
        $map["content_id"] = $itemId;
        $result = $activityAwards->where($map)->select();
        $this->ajaxReturn($result);
    }

    public function saveRewards(){
        checkSession();
        $activityAward = D("ActivityAwards");
        if(!$activityAward->create(I("post."),1)){
            $this->ajaxReturn($activityAward->getError());
        }else{
            $activityAward -> id = null;
            $activityAward -> params = json_encode(array("is_expire"=>I("post.is_expire")),JSON_NUMERIC_CHECK);
            $id = $activityAward->add();
            if($id){
                save_operate_log("saveAwards", json_encode(I("post."),JSON_UNESCAPED_UNICODE));
                $itemId = I("post.content_id");

                $activityItems = D("ActivityItems");
                $rewards = $activityItems->where("id=".$itemId)->getField("rewards");
                if(empty($rewards)){
                    $rewards = $id;
                }else{
                    $rewards .= ",".$id;
                }
                $activityItems -> rewards = $rewards;
                $activityItems -> where("id=".$itemId)->save();

                $this->ajaxReturn(1);
            }else{
                $this -> ajaxReturn(0);
            }

        }

    }
    public function delItemAward($itemId,$awardId){
        checkSession();
        $activityAward = D("ActivityAwards");
        $activityAward->delete($awardId);
        save_operate_log("delAwards", "Delete Awards Id:".$awardId);
        $activityItems = D("ActivityItems");
        $rewards = $activityItems->where("id=".$itemId)->getField("rewards");
        $rewardsArr = explode(",",$rewards);
        $index = array_search($awardId,$rewardsArr);
        if(!empty($index) || $index == 0){
            unset($rewardsArr[$index]);
        }
        $rewardsStr = implode(",",$rewardsArr);
        $activityItems -> rewards = $rewardsStr;
        $activityItems -> where("id=".$itemId)->save();
        $this->ajaxReturn(1);
    }
    public function getAwardById($id){
        checkSession();
        $activityAwards = D("ActivityAwards");
        $result = $activityAwards->find($id);
        $this->ajaxReturn($result);
    }
    public function updateReward(){
        checkSession();
        $activityAward = D("ActivityAwards");
        $activityAward->create();
        $activityAward->params = json_encode(array("is_expire"=>I("post.is_expire")),JSON_NUMERIC_CHECK);
        $activityAward->where("id=".I("post.id"))->save();

        $awardIds = $activityAward->where("content_id=".I("post.content_id"))->order("`order`")->field("id")->select();
        for($i = 0;$i<count($awardIds);$i++){
            $awardIds[$i] = $awardIds[$i]["id"];
        }
        $activityItems = D("ActivityItems");
        $activityItems->rewards = implode(",",$awardIds);
        $activityItems->where("id=".I("post.content_id"))->save();

        save_operate_log("updateAwards", json_encode(I("post."),JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn(1);
    }
}
