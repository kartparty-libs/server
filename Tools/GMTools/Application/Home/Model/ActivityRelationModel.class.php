<?php
namespace Home\Model;

use \Think\Model;

class ActivityRelationModel extends Model
{
    protected $_validate = array(
        array('level','require','等级限制必须填写！'),
        array('version','require','版本号必须填写！'),
    );
}