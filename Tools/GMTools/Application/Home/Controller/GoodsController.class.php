<?php
namespace Home\Controller;

use Think\Controller;
use Think\Model;

class GoodsController extends Controller
{
    public function show()
    {
        checkSession();
        $goodsShelf = D("GoodsShelf");
        $result = $goodsShelf->select();

        $activities = D("Activities");
        $activity = $activities->select();
        $this->assign("act",$activity);

        $this->assign("goodsShelf",$result);
        $this->display("goodsManage");
    }
    public function GoodsDel($id)
    {
        checkSession();
        $goodsShelf = D("GoodsShelf");
        $goodsShelf->delete($id);
        $actRelation = D("ActivityRelation");
        $actRelation->where("good_id=".$id)->delete();
        save_operate_log("delAwards", "Delete GoodsShelf Id:".$id);
        $this->ajaxReturn(1);
    }

    public function saveGoods(){
        checkSession();
        $goodsShelf = D("GoodsShelf");
        if(!$goodsShelf->create(I("post."),1)){
            $this->ajaxReturn($goodsShelf->getError());
        }else{
            $goodsShelf -> world = implode(",",I("post.world"));
            $goodsShelf->add();
            save_operate_log("saveGoodsShelf", json_encode(I("post."),JSON_UNESCAPED_UNICODE));
            $this->ajaxReturn(1);
        }
    }

    public function getGoodById($goodId){
        checkSession();
        $goodsShelf = D("GoodsShelf");
        $result = $goodsShelf->find($goodId);
        $this->ajaxReturn($result);
    }

    public function updateGood(){
        checkSession();
        $goodsShelf = D("GoodsShelf");
        $goodsShelf->create();
        $goodsShelf->where("id=".I("post.id"))->save();
        save_operate_log("updateGoodsShelf", json_encode(I("post."),JSON_UNESCAPED_UNICODE));
        $this->ajaxReturn(1);
    }
    public function syncPage(){
        checkSession();
        $goodsShelf = D("GoodsShelf");
        $result = $goodsShelf->select();
        $this->assign("platform",C("PLATFORM_URL"));
        $this->assign("goods",$result);
        $this->display("syncPage");
    }

    public function sync(){
        checkSession();
        $goods = D("GoodsShelf");
        if(I("post.all") == "on"){
            $serverIds = array(strval(0));
        }else{
            $serverIds = I("post.serverid");
        }
        session("plat",I("post.plat"));
        $resultArr = array();
        for($i = 0;$i < count($serverIds);$i++){
            $data = $goods->syncData($serverIds[$i],I("post.good"));
            //var_dump(json_encode($data,JSON_NUMERIC_CHECK|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
            //$result = postData("http://172.16.1.39:10000/activities", json_encode($data,JSON_NUMERIC_CHECK|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
            //腾讯版本商业化服务器端口
            //$result = postData(C("GM_POST_URL") . "activities", json_encode($data));

            //360商业化服务器端口
            $result = phpPostData("activity",$data,3);
            $resultArr[$serverIds[$i]] = $result["ret"];
        }
        $this->ajaxReturn($resultArr);
    }
    public function index(){
        /*$model = new Model();
        $result = $model->query("select activity_id,GROUP_CONCAT(id) as items from activity_items GROUP BY activity_id");;
        for($i = 0;$i<count($result);$i++){
            $model->execute("update activities set items = '".$result[$i]['items']."' where id = ".$result[$i]["activity_id"]);

        }*/
        $this->display();
    }

    public function revertData(){
        $activity = D("Activity");
        $where["serverid"] = "6019";
        $result = $activity->where($where)->find();
        $activityData = json_decode($result["activities"],true);
        $activities = $activityData["activities"];
        $arr = array();
        for($i = 0;$i < count($activities);$i++){
            $act = $activities[$i];
            $activity = D("Activities");
            $activity->id = $act["id"];
            $activity->order = $act["order"];
            $activity->category = $act["category"];
            $activity->icon = $act["icon"];
            $activity->id = $act["id"];
            $activity->desc = $act["desc"];
            $activity->position = $act["position"];
            $activity->items = implode(",",$act["items"]);
            $activity->type = $act["type"];
            $activity->name = $act["name"];
            $activity->create_time = date("Y-m-d H:i:s");
            //$activity->add();
            var_dump($act["id"]."\r\n");
            $md5 = md5(json_encode($act));
            if(!in_array($arr,$md5)){
                $activityRelation = D("ActivityRelation");
                $activityRelation->good_id = 22;
                $activityRelation->activity_id = $act["id"];
                $activityRelation->name = $act["name"];
                $activityRelation->state = $act["state"];
                $activityRelation->level = $act["level"];
                $activityRelation->show_start = json_encode($act["show_start"]);
                $activityRelation->show_end = json_encode($act["show_end"]);
                $activityRelation->start_time = json_encode($act["start_time"]);;
                $activityRelation->end_time = json_encode($act["end_time"]);;
                $activityRelation->version = $act["version"];
                $activityRelation->order = $act["order"];
                //$activityRelation->add();
                array_push($arr,$md5);
            }
        }

        $items = $activityData["items"];
        for($i = 0;$i < count($items);$i++){
            $item = $items[$i];
            $activityItems = D("ActivityItems");
            $activityItems->id = $item["id"];
            $activityItems->activity_id = $item["activity_id"];
            $activityItems->key = $item["key"];
            $activityItems->category = $item["category"];
            $activityItems->name = $item["name"];
            $activityItems->params = json_encode($item["params"]);
            $activityItems->rewards = implode(",",$item["rewards"]);
            //$activityItems->add();
        }

        $rewards = $activityData["rewards"];
        for($i = 0;$i < count($rewards);$i++){
            $reward = $rewards[$i];
            $activityAwards = D("ActivityAwards");
            $activityAwards->id = $reward["id"];
            $activityAwards->content_id = $reward["content_id"];
            $activityAwards->item_id = $reward["item_id"];
            $activityAwards->number = $reward["number"];
            $activityAwards->order = $reward["order"];
            $activityAwards->params = json_encode($reward["params"]);
            var_dump(json_encode($reward["params"])."\r\n");
            //$activityAwards->add();
        }
        //var_dump($activityData["activities"][2]);
    }
}

