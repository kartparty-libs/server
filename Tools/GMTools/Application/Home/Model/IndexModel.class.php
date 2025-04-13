<?php
namespace Home\Model;

use \Think\Model;

class IndexModel extends Model
{
    
    /**
     * 登录验证
     * @param $username 用户名
     * @param $password 登录密码
     * @return mixed
     */
    public function loginCheck($username, $password,$platform)
    {
         /**
         * 平台归属关系
         * 1是渠道
         * 2是玩吧
         */
        $Ascription ["YunGe"] = 1;
        $Ascription ["WeiXin"] = 1;
        $Ascription ["YYB"] = 1;
        $Ascription ["QuDao"] = 1;
        $Ascription ["TYTS"] = 1;
        $Ascription ["WanBa"] = 2;

        $User = M("UserInfo");
        $map["user_name"] = $username;
        $userInfo = $User->where($map)->find();
        $result["status"] = 0;
        if ( $userInfo["platform"] != 0 and !empty($userInfo) ){
            if ( $userInfo["platform"] !=  $Ascription [$platform] ){
                $result["info"] = "用户没有操作该平台权限!!";
                return $result;
            }
        }
        if (empty($userInfo)) {
            $result["info"] = "用户不存在!";
        } else if ($password == $userInfo["password"]) {
            session("user", $userInfo);
            $result["status"] = 1;
        } else {
            $result["info"] = "密码不正确";
        }
        return $result;
    }
}