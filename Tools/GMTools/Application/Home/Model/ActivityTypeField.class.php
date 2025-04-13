<?php
namespace Home\Model;

use \Think\Model;

class ActivityTypeField extends Model
{
    protected $insertFields = array('activity_type','type_key','key_name','key_order','type_field','type_name','enum');
}