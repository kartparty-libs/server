<?php
namespace Home\Model;

use \Think\Model;

class ActivityAwardsModel extends Model
{
    protected $_validate = array(
        array('number','require','道具数量必须填写！'),
    );
}