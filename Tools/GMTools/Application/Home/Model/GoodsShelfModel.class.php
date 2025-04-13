<?php
namespace Home\Model;

use \Think\Model;

class GoodsShelfModel extends Model
{
    protected $_validate = array(
        array('name','require','{%tip_goodshelf_name}'),
    );

    public function syncData($serverId,$goodId){
        $goodStr = "in (".implode($goodId,",").")";
        $Model = new Model(); // 实例化一个model对象 没有对应任何数据表
        $activities = $Model->query("select CONCAT(act.id,',',rela.version) as `key`,act.id,act.name,act.desc,rela.state,act.type,".
            "act.category,act.position,act.icon,rela.version,rela.start_time,rela.end_time,".
            "rela.show_start,rela.show_end,rela.level,rela.order,act.items from activities act INNER JOIN ".
            "activity_relation rela on act.id = rela.activity_id where rela.good_id ".$goodStr);
        $activityArr = array();
        for($i = 0;$i<count($activities);$i++){
            $record = $activities[$i];
            foreach($record as $key => $value){
                if(strpos($key,"start")!==false||strpos($key,"end")!==false){
                    $record[$key] = json_decode($value);
                }
                if($key == "items" || $key == "key"){
                    if($key == "items"){
                        $itemStr .= ",".$value;
                    }
                    $record[$key] = explode(",",$value);

                }
            }
             $activityArr[$i] = $record;
        }
        $activityItmes = D("ActivityItems");
        $map["id"] = array("in",substr($itemStr,1));
        $items = $activityItmes->where($map)->order("activity_id,`key`")->select();
        for($i = 0;$i<count($items);$i++){
            $item = $items[$i];
            foreach($item as $key => $value){
                if($key == "params"){
                    $item[$key] = json_decode($value);
                }
                if($key == "rewards"){
                    if(!empty($value)){
                        $item[$key] = explode(",",$value);
                        $rewardStr .= ",".$value;
                    }else{
                        $item[$key] = array();
                    }
                }
            }
            $items[$i] = $item;
        }
        $activityAwards = D("ActivityAwards");
        if(empty($rewardStr) || strlen($rewardStr) == 0){
            $awards = array();
        }else{
            $map["id"] = array("in",substr($rewardStr,1));
            $awards = $activityAwards->where($map)->order("content_id,`order`")->select();
            for($i = 0;$i<count($awards);$i++){
                $award = $awards[$i];
                foreach($award as $key => $value){
                    if($key=="params"){
                        $award[$key] = json_decode($value);
                        $awards[$i] = $award;
                    }
                }
            }
        }
        $arr["serverid"] = $serverId;
        $arr["activities"] = $activityArr;
        $arr["items"] = $items;
        $arr["rewards"] = $awards;
        return $arr;
    }
}