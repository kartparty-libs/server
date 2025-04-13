<?php
namespace Home\Model;

use \Think\Model;

class ItemsModel extends Model
{
    /**
     * 根据道具名称模糊查询道具信息
     * @param $itemName 道具名称
     * @return mixed
     */
    public function getItemsByVague($itemName)
    {
        $data["itemname"] = array("like","%$itemName%");
        $info = $this->where($data)->select();
        return $info;
    }
}