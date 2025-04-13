<?php
return array(

    //'配置项'=>'配置值'
    'DB_TYPE' => 'mysql', // 数据库类型

    'DB_HOST' => '127.0.0.1', // 服务器地址

    'DB_NAME' => 'gmtools_ceshi', //数据库名
    'DB_CHARSET' => 'utf8',

    'DB_USER' => 'root', // 用户名

    'DB_PWD' => '', // 密码

    'DB_PORT' => 3306, // 端口

    'MEMCACHE_IP' => '',

    'MEMCACHE_PORT' => '',

    'MEMCACHE_PREFIX' => '',
    
    'PLATFORM_URL' => array(
        'CeShi' => 'http://127.0.0.1:10000/',
        'WanBa' => 'http://10.12.253.2:10000/',
    ),

        //充值端口地址
    'PLATFORM_CHARGE__URL' => array(
        'CeShi' => 'http://127.0.0.1:10002/',
        'WanBa' => 'http://10.12.253.2:10002/',
    ),

    //运营活动端口地址
    'PLATFORM_ACTIVI__URL' => array(
        'CeShi' => 'http://127.0.0.1:10003/',
        'WanBa' => 'http://10.12.253.2:10003/',
    ),

    //player_server地址
    'PLATFORM_PLAYER__URL' => array(
        'CeShi' => 'http://127.0.0.1:10001/',
        'WanBa' => 'http://10.12.253.2:10001/',
    ),
    //server_list数据库信息
    'PLATFORM_LIST__INFO' => array(
        'DBName' => 'union_district_log',   //数据库名
        'DBAddr' => '140.143.151.120:30001',// 服务器地址
        'DBUser' => 'ssjxz',// 用户名
        'DBPwd' => 'uValDJ^%D+0%aA',// 密码
    ),   
    //查询结果分页数
    'PAGE_PIECE_NUM' => '20',

    'LANG_SWITCH_ON' => true,   // 开启语言包功能

    'LANG_AUTO_DETECT' => true, // 自动侦测语言 开启多语言功能后有效

    'LANG_LIST'        => 'zh-cn,en-us', // 允许切换的语言列表 用逗号分隔

    'VAR_LANGUAGE'     => 'l', // 默认语言切换变量

    'SESSION_PREFIX' => 'gm',
);
