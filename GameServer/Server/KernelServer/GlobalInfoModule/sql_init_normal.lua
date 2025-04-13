return {
    [[   
  SET FOREIGN_KEY_CHECKS=0;
  ]],
    [[
  CREATE TABLE `dbinfo` (
    `dbversion` int(10) unsigned NOT NULL DEFAULT '0'
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
  ]],
    [[
  INSERT INTO `dbinfo` set `dbversion` = 0;
  ]],
    [[
  CREATE TABLE `globalinfo` (
    `serverid` int(11) NOT NULL,
    `opentime` bigint(20) NOT NULL DEFAULT '0',
    `realopentime` bigint(20) unsigned NOT NULL DEFAULT '0',
    `mailnum` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '邮件id最大值',
    `roleindex` int(11) NOT NULL DEFAULT '0',
    `guildindex` int(11) NOT NULL DEFAULT '0' COMMENT '帮派id最大值',
    `chatworldindex` int(11) NOT NULL DEFAULT '0' COMMENT '世界聊天最大值',
    `refreshtime` bigint(20) NOT NULL DEFAULT '0',
    `marrynum` bigint(20) NOT NULL DEFAULT '0',
    `marryindex` int(11) NOT NULL DEFAULT '0' COMMENT '情缘的总量',
    `friendindex` int(11) NOT NULL DEFAULT '0' COMMENT '好友的总量',
    `shuttime` bigint(20) NOT NULL DEFAULT '0' COMMENT '关服时间',
    `rank1v1ver` int(11) NOT NULL DEFAULT '0' COMMENT '1v1榜版本号',
    `rank3v3ver` int(11) NOT NULL DEFAULT '0' COMMENT '3v3榜版本号',
    `hefu` bigint(20) NOT NULL DEFAULT '0' COMMENT '合服时间戳',
    `hefutimes` smallint(6) NOT NULL DEFAULT '0' COMMENT '次数',
    `incbattleid` varchar(255) NOT NULL DEFAULT '0' COMMENT '自增战斗Id',
    PRIMARY KEY (`serverid`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
  ]],
    [[
  CREATE TABLE `role` (
    `accountid` varchar(128) NOT NULL,
    `roleid` char(32) NOT NULL,
    `rolename` char(32) NOT NULL COMMENT '角色名',
    `newflag` tinyint(4) NOT NULL DEFAULT '1',
    `createtime` bigint(20) NOT NULL DEFAULT '0' COMMENT '创建时间',
    `totaltime` bigint(20) NOT NULL DEFAULT '0',
    `channel` varchar(255) NOT NULL DEFAULT '',
    `refreshtime` bigint(20) NOT NULL COMMENT '每日刷新时间',
    `loginnum` smallint(6) NOT NULL DEFAULT '1',
    `todaytime` int(11) NOT NULL DEFAULT '0' COMMENT '今日在线总时间',
    `logouttime` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '登出时间',
    `kartkey` char(32) NOT NULL DEFAULT '' COMMENT '激活码',
    `email` char(128) NOT NULL DEFAULT '' COMMENT '绑定邮箱',
    `isr` tinyint(4) NOT NULL DEFAULT '0',
    PRIMARY KEY (`roleid`),
    KEY `role_accountid_index` (`accountid`) USING BTREE,
    KEY `role_rolename_index` (`rolename`) USING BTREE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
  ]],
    [[
  CREATE TABLE `role_basicinfo` (
    `roleid` char(32) NOT NULL COMMENT '角色id',
    `level` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '等级',
    `exp` double NOT NULL DEFAULT '0' COMMENT '经验',
    `viplv` tinyint(4) NOT NULL DEFAULT '0' COMMENT 'vip等级',
    `gold` int(11) NOT NULL DEFAULT '0' COMMENT '金币',
    `diamond` int(11) NOT NULL DEFAULT '0' COMMENT '钻石',
    `energy` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '体力',
    `head` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '头像',
    `playercfgid` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '玩家皮肤id',
    `carcfgid` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '赛车id',
    `score` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '积分',
    PRIMARY KEY (`roleid`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
  ]],
    [[
CREATE TABLE `role_taskinfo` (
  `roleid` char(32) NOT NULL COMMENT '角色id',
  `taskinfo` varchar(2048) NOT NULL DEFAULT '' COMMENT '任务信息',
  `completerecord` varchar(2048) NOT NULL DEFAULT '' COMMENT '任务完成次数',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]],
    [[
CREATE TABLE `rank_score` (
  `roleid` char(50) NOT NULL COMMENT '角色id',
  `mainvalue` bigint(20) NOT NULL COMMENT '玩家积分',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='积分榜';
]],
    [[
CREATE TABLE `invite` (
`roleid` char(50) NOT NULL COMMENT '角色id',
`invitecodes` varchar(2048) NOT NULL DEFAULT '' COMMENT '邀请码列表',
PRIMARY KEY (`roleid`)
)  ENGINE=InnoDB DEFAULT CHARSET=utf8;
]]
}
