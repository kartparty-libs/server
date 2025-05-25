SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE IF NOT EXISTS `globalinfo` (
  `serverid` int(11) NOT NULL,
  `opentime` bigint(20) NOT NULL DEFAULT '0' COMMENT '服务器创建时间戳',
  `zerotime` bigint(20) NOT NULL DEFAULT '0' COMMENT '今日凌晨时间',
  `cartokenscorepoolvalue` bigint(20) NOT NULL DEFAULT '0' COMMENT '赛车挖矿池剩余token积分',
  `diamondtokenscorepoolvalue` bigint(20) NOT NULL DEFAULT '0' COMMENT '钻石挖矿池剩余token积分',
  PRIMARY KEY (`serverid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mining_serverinfo` (
  `serverid` int(11) NOT NULL,
  `totalminingcount` int(11) NOT NULL DEFAULT '0' COMMENT '全服总挖矿人数',
  `totalreceivecount` int(11) NOT NULL DEFAULT '0' COMMENT '全服总领取积分人数',
  `cartotalminingcount` int(11) NOT NULL DEFAULT '0' COMMENT '全服赛车总挖矿人数',
  `diamondtotalminingcount` int(11) NOT NULL DEFAULT '0' COMMENT '全服钻石总挖矿人数',
  `cartotalminingvalue` bigint(20) NOT NULL DEFAULT '0' COMMENT '全服赛车总挖矿价值',
  `diamondtotalminingvalue` bigint(20) NOT NULL DEFAULT '0' COMMENT '全服钻石总挖矿价值',
  PRIMARY KEY (`serverid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mining_giftcodeinfo` (
  `code` varchar(64) NOT NULL COMMENT '兑换码',
  `roleid` bigint(20) NOT NULL COMMENT '领取玩家Id',
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mining_receivetokeninfo` (
  `account` varchar(64) NOT NULL COMMENT '账号',
  `roleid` bigint(20) NOT NULL COMMENT '领取玩家Id',
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*----------------后续添加字段----------------*/

 /*ALTER TABLE `tablename`  
ADD COLUMN `addtext` VARCHAR(128) DEFAULT NULL COMMENT '添加字段';*/