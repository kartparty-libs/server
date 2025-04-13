
return {
[[
    SET FOREIGN_KEY_CHECKS=0;
]],

[[
CREATE TABLE `backup_rank1v1` (
  `score` bigint(20) unsigned NOT NULL COMMENT '积分',
  `roleid` char(50) NOT NULL COMMENT '角色id',
  `name` char(32) NOT NULL DEFAULT '' COMMENT '角色名'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='1v1排行备份表（用于补发奖励）';
]],

[[
CREATE TABLE `backup_rank3v3` (
  `score` bigint(20) unsigned NOT NULL COMMENT '积分',
  `roleid` char(50) NOT NULL COMMENT '角色id',
  `name` char(32) NOT NULL DEFAULT '' COMMENT '角色名'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='3v3排行备份表（用于补发奖励）';
]],

[[
CREATE TABLE `bridgewar` (
  `serverid` int(11) NOT NULL DEFAULT '0',
  `result` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`serverid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]],

[[
CREATE TABLE `bridgewar_rank` (
  `groupid` int(11) NOT NULL DEFAULT '0',
  `rank` tinyint(4) NOT NULL DEFAULT '0',
  `roleid` char(50) NOT NULL,
  `name` char(32) NOT NULL,
  `yellow` int(11) NOT NULL DEFAULT '0',
  `blue` int(11) NOT NULL DEFAULT '0',
  `viplevel` tinyint(4) NOT NULL DEFAULT '0',
  `head` tinyint(4) NOT NULL,
  `prof` tinyint(4) NOT NULL,
  `curfiara` int(11) NOT NULL DEFAULT '0',
  `clothes` int(11) NOT NULL DEFAULT '0',
  `gemlevel` tinyint(3) NOT NULL DEFAULT '0',
  `curapparel` int(11) NOT NULL DEFAULT '0',
  `curdarklike` int(11) NOT NULL DEFAULT '0',
  `curkungfu` int(11) NOT NULL DEFAULT '0',
  `curarray` tinyint(4) NOT NULL DEFAULT '0',
  `curornament` int(11) NOT NULL DEFAULT '0',
  `curweapon` int(11) NOT NULL DEFAULT '0',
  `weaponquality` tinyint(4) NOT NULL DEFAULT '1',
  `iswake` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rank`,`groupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]],

[[
CREATE TABLE `dbinfo` (
  `dbversion` int(10) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]],

[[
CREATE TABLE `globalinfo` (
  `serverid` int(11) NOT NULL,
  `opentime` bigint(20) NOT NULL DEFAULT '0',
  `mailnum` bigint(20) unsigned NOT NULL DEFAULT '0',
  `roleindex` int(11) NOT NULL DEFAULT '0',
  `guildindex` int(11) NOT NULL DEFAULT '0',
  `refreshtime` bigint(20) NOT NULL DEFAULT '0',
  `marrynum` int(11) NOT NULL DEFAULT '0',
  `shuttime` bigint(20) NOT NULL DEFAULT '0' COMMENT '关服时间',
  `rank1v1ver` int(11) NOT NULL DEFAULT '0' COMMENT '1v1榜版本号',
  `rank3v3ver` int(11) NOT NULL DEFAULT '0' COMMENT '3v3榜版本号',
  `bridgeholelevel` int(11) NOT NULL DEFAULT '0' COMMENT '荻花洞窑等级',
  PRIMARY KEY (`serverid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]],

[[
CREATE TABLE `rank_match` (
  `rank` int(11) NOT NULL COMMENT '名次',
  `roleid` char(50) NOT NULL COMMENT '角色id',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='排名赛排行榜';
]],

[[
CREATE TABLE `rank_score1v1` (
  `score` bigint(20) unsigned NOT NULL COMMENT '1v1积分',
  `roleid` char(50) NOT NULL COMMENT '角色id',
  `name` char(32) NOT NULL COMMENT '角色名',
  `prof` tinyint(4) unsigned NOT NULL COMMENT '职业',
  `cp` bigint(20) NOT NULL COMMENT '战斗力',
  `viplv` int(11) NOT NULL DEFAULT '0' COMMENT 'vip等级',
  `yellow` int(11) NOT NULL DEFAULT '0' COMMENT '黄钻',
  `blue` int(11) NOT NULL DEFAULT '0' COMMENT '蓝钻'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='1v1排行榜';
]],

[[
CREATE TABLE `rank_score3v3` (
  `score` bigint(20) unsigned NOT NULL COMMENT '3v3积分',
  `roleid` char(50) NOT NULL COMMENT '角色id',
  `name` char(32) NOT NULL COMMENT '角色名',
  `prof` tinyint(3) unsigned NOT NULL COMMENT '职业',
  `cp` bigint(20) NOT NULL COMMENT '战斗力',
  `viplv` int(11) NOT NULL DEFAULT '0' COMMENT 'vip等级',
  `yellow` int(11) NOT NULL DEFAULT '0' COMMENT '黄钻',
  `blue` int(11) NOT NULL DEFAULT '0' COMMENT '蓝钻'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='3v3排行榜';
]],

[[
CREATE TABLE `role_image` (
  `roleid` char(50) NOT NULL COMMENT '角色id',
  `name` char(32) NOT NULL COMMENT '角色名',
  `prof` tinyint(4) NOT NULL COMMENT '职业',
  `level` int(11) NOT NULL COMMENT '等级',
  `tlevel` int(11) NOT NULL COMMENT '转生等级',
  `fashion` int(11) NOT NULL COMMENT '时装',
  `wraps` int(4) NOT NULL COMMENT '翅膀',
  `sword` tinyint(4) NOT NULL COMMENT '法宝',
  `array` tinyint(4) NOT NULL COMMENT '法阵',
  `combat` bigint(20) NOT NULL COMMENT '战斗力',
  `weaponid` int(11) NOT NULL COMMENT '武器id',
  `skill` varchar(255) NOT NULL DEFAULT '' COMMENT '技能',
  `combowin` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '连胜',
  `viplv` smallint(6) NOT NULL DEFAULT '0' COMMENT 'vip等级',
  `title` smallint(6) NOT NULL DEFAULT '0' COMMENT '称号',
  `gtitle` smallint(6) NOT NULL DEFAULT '0' COMMENT '头衔',
  `server` int(11) NOT NULL DEFAULT '0' COMMENT '服务器ID',
  `guild` char(32) NOT NULL COMMENT '工会ID',
  `hp` int(11) NOT NULL COMMENT '血量',
  `attack` int(11) NOT NULL COMMENT '攻击力',
  `defence` int(11) NOT NULL COMMENT '防御',
  `hit` int(11) NOT NULL COMMENT '命中',
  `dodge` int(11) NOT NULL COMMENT '闪避',
  `crit` int(11) NOT NULL COMMENT '暴击',
  `uncrit` int(11) NOT NULL COMMENT '免暴',
  `exact` int(11) NOT NULL COMMENT '精确',
  `resist` int(11) NOT NULL COMMENT '招架',
  `critdmg` int(11) NOT NULL COMMENT '暴击伤害',
  `critcut` int(11) NOT NULL COMMENT '暴击减免',
  `dmgadd` int(11) NOT NULL COMMENT '伤害加成',
  `dmgcut` int(11) NOT NULL COMMENT '伤害减免',
  `dodgerate` int(11) NOT NULL COMMENT '绝对闪避',
  `critrate` int(11) NOT NULL COMMENT '绝对暴击',
  `resistrate` int(11) NOT NULL COMMENT '绝对招架',
  `vertigoabs` int(11) NOT NULL COMMENT '被眩晕几率降低（千分比）',
  `vertigobehurtabs` int(11) NOT NULL COMMENT '被眩晕时受到伤害百分比降低（千分比）',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色镜像数据（排名赛）';
]],

[[
CREATE TABLE `role_rankmatchreport` (
  `roleid` char(50) NOT NULL COMMENT '角色id',
  `index` tinyint(4) NOT NULL COMMENT '序号',
  `kind` tinyint(4) NOT NULL COMMENT '战报类型（1挑战胜利，2挑战失败，3被挑胜利，4被挑失败）',
  `oppname` char(32) NOT NULL COMMENT '对手名字',
  `change` smallint(6) NOT NULL COMMENT '变化(0排名不变，>0新排名)',
  `time` bigint(20) NOT NULL DEFAULT '0' COMMENT '记录时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='排名赛战报';
]],

[[
CREATE TABLE `role_serverid` (
  `roleid` char(50) NOT NULL COMMENT '角色id',
  `serverid` int(11) NOT NULL COMMENT '角色所属服务器id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色服务器表';
]],
    
[[
    INSERT INTO `dbinfo` set `dbversion` = 0;
]],
}


