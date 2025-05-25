SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE IF NOT EXISTS `globalinfo` (
  `serverid` int(11) NOT NULL,
  `opentime` bigint(20) NOT NULL DEFAULT '0' COMMENT '服务器创建时间戳',
  `zerotime` bigint(20) NOT NULL DEFAULT '0' COMMENT '今日凌晨时间',
  `roleindex` int(11) NOT NULL DEFAULT '0'COMMENT '玩家id自增',
  `seasonid` int(11) NOT NULL DEFAULT '0'COMMENT '赛季Id',
  `seasonstateenum` smallint(6) NOT NULL DEFAULT '0'COMMENT '赛季状态',
  `changenextstatetime` bigint(20) NOT NULL DEFAULT '0' COMMENT '切换赛季状态时间戳',
  `seasonmedaltimeindex` int(11) NOT NULL DEFAULT '0'COMMENT '排行时间下标',
  PRIMARY KEY (`serverid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*----------------玩家相关表----------------*/

CREATE TABLE IF NOT EXISTS `role` (
  `account` varchar(128) NOT NULL,
  `roleid` bigint(20) NOT NULL,
  `rolename` char(32) NOT NULL COMMENT '角色名',
  `createtime` bigint(20) NOT NULL DEFAULT '0' COMMENT '创建时间戳',
  `loginnum` smallint(6) NOT NULL DEFAULT '1' COMMENT '累计登录',
  `lasthandletime` bigint(20) NOT NULL DEFAULT '0' COMMENT '最后操作时间戳',
  `zerotime` bigint(20) NOT NULL DEFAULT '0' COMMENT '零点时间戳',
  `email` char(255) NOT NULL DEFAULT '' COMMENT '官网邮箱',
  `platformenum` smallint(6) NOT NULL DEFAULT '0' COMMENT '平台枚举',
  `platforminfo` varchar(1024) NOT NULL DEFAULT '' COMMENT '平台信息',
  `kartkey` char(32) NOT NULL DEFAULT '' COMMENT '官网激活码',
  PRIMARY KEY (`roleid`),
  KEY `role_account_index` (`account`) USING BTREE,
  KEY `role_rolename_index` (`rolename`) USING BTREE,
  KEY `role_kartkey_index` (`kartkey`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_baseinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `headid` smallint(6) NOT NULL DEFAULT '1' COMMENT '头像Id',
  `gold` bigint(20) NOT NULL DEFAULT '0' COMMENT '金币',
  `diamond` bigint(20) NOT NULL DEFAULT '0' COMMENT '钻石',
  `cultivategold` bigint(20) NOT NULL DEFAULT '0' COMMENT '养成收益累计金币',
  `tokenScore` bigint(20) NOT NULL DEFAULT '0' COMMENT 'token积分',
  `monetary` bigint(20) NOT NULL DEFAULT '0' COMMENT '消费金额/美金 扩大1000',
  `rolecfgid` int(11) NOT NULL DEFAULT '1' COMMENT '角色配置Id',
  `carcfgid` int(11) NOT NULL DEFAULT '1' COMMENT '赛车配置Id',
  `totalreceivetoken` bigint(20) NOT NULL DEFAULT '0' COMMENT '总领取token数',
  `usdt` bigint(20) NOT NULL DEFAULT '0' COMMENT '消费USDT记录',
  `ton` bigint(20) NOT NULL DEFAULT '0' COMMENT '消费TON记录',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_taskinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `taskinfo` varchar(10240) NOT NULL DEFAULT '' COMMENT '任务信息',
  `completerecord` varchar(10240) NOT NULL DEFAULT '' COMMENT '任务完成次数',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_treasurechestinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `treasurechestindex` int(11) NOT NULL DEFAULT '0'COMMENT '宝箱id自增',
  `treasurechestinfo` varchar(4096) NOT NULL DEFAULT '' COMMENT '宝箱信息',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_carcultivateinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `lastsettlementtime` bigint(20) NOT NULL DEFAULT '0'COMMENT '上次结算时间戳',
  `lastfreegetspeeduptime` bigint(20) NOT NULL DEFAULT '0'COMMENT '上次领取免费加速时长时间戳',
  `speedupendtime` bigint(20) NOT NULL DEFAULT '0'COMMENT '加速结束时间戳',
  `carcultivateinfo` varchar(2048) NOT NULL DEFAULT '' COMMENT '赛车养成信息',
  `isautoupgradecar` smallint(6) NOT NULL DEFAULT '0' COMMENT '是否自动升级',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_luckyboxinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `maxluckyscroe` int(11) NOT NULL DEFAULT '0'COMMENT '最大幸运分',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_mininginfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `carminingdata` varchar(128) NOT NULL DEFAULT '' COMMENT '赛车挖矿质押数据',
  `carminingdatas` varchar(10240) NOT NULL DEFAULT '' COMMENT '赛车挖矿待预结算质押数据列表',
  `carlastpresettlementtime` bigint(20) NOT NULL DEFAULT '0'COMMENT '赛车挖矿上次预结算截止时间',
  `carpresettlementtokenscore` bigint(20) NOT NULL DEFAULT '0'COMMENT '赛车挖矿预结算的token积分',
  `carsettlementtokenscore` bigint(20) NOT NULL DEFAULT '0'COMMENT '赛车挖矿已结算的token积分',
  
  `diamondminingdata` varchar(128) NOT NULL DEFAULT '' COMMENT '钻石挖矿质押数据',
  `diamondminingdatas` varchar(10240) NOT NULL DEFAULT '' COMMENT '钻石挖矿待预结算质押数据列表',
  `diamondlastpresettlementtime` bigint(20) NOT NULL DEFAULT '0'COMMENT '钻石挖矿上次预结算截止时间',
  `diamondpresettlementtokenscore` bigint(20) NOT NULL DEFAULT '0'COMMENT '钻石挖矿预结算的token积分',
  `diamondsettlementtokenscore` bigint(20) NOT NULL DEFAULT '0'COMMENT '钻石挖矿已结算的token积分',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_shopinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `todayshopbuycountrecord` varchar(1024) NOT NULL DEFAULT '' COMMENT '商城今日购买次数记录',
  `totalshopbuycountrecord` varchar(1024) NOT NULL DEFAULT '' COMMENT '商城总购买次数记录',
  `buyshopitemwaitverifys` varchar(1024) NOT NULL DEFAULT '' COMMENT '待验证购买商品集合',
  `buyshopitemverifieds` varchar(1024) NOT NULL DEFAULT '' COMMENT '商品验证通过待通知客户端列表',
  `firstshopbuyrecord` varchar(1024) NOT NULL DEFAULT '' COMMENT '首充购买记录',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_mapinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `totalcompletecount` int(11) NOT NULL DEFAULT '0'COMMENT '总比赛完成次数',
  `todaycompletecount` int(11) NOT NULL DEFAULT '0'COMMENT '今日比赛完成次数',
  `winningstreaks` varchar(1024) NOT NULL DEFAULT '' COMMENT '连胜次数',
  `maphistorydatas` varchar(10240) NOT NULL DEFAULT '' COMMENT '历史记录',
  `totalmedalcounts` varchar(128) NOT NULL DEFAULT '' COMMENT '总奖牌数量',
  `weekmedalcounts` varchar(128) NOT NULL DEFAULT '' COMMENT '周奖牌数量',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_inviteinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `ownerinviteplayerinfo` varchar(64) NOT NULL DEFAULT '' COMMENT '邀请人信息',
  `inviteplayerinfolist` varchar(5120) NOT NULL DEFAULT '' COMMENT '接收邀请的玩家列表',
  `receiverewardrecord` varchar(5120) NOT NULL DEFAULT '' COMMENT '领取记录',
  `rebaterecord` varchar(5120) NOT NULL DEFAULT '' COMMENT '返佣记录',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_energyinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `currenergy` int(11) NOT NULL DEFAULT '0'COMMENT '当前体力',
  `lastrecovertime` bigint(20) NOT NULL DEFAULT '0'COMMENT '最后恢复体力时间',
  `todaybuycount` int(11) NOT NULL DEFAULT '0'COMMENT '今日购买次数',
  `todaybuypveitemcount` int(11) NOT NULL DEFAULT '0'COMMENT '今日购买Pve道具补充次数',
  `isinitenergy` smallint(6) NOT NULL DEFAULT '0' COMMENT '是否初始化了体力',
  `isinitpveitem` smallint(6) NOT NULL DEFAULT '0' COMMENT '是否初始化了Pve道具数量',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_luckyturntableinfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `loginnum` int(11) NOT NULL DEFAULT '0'COMMENT '幸运转盘登入天数',
  `turntablecount` int(11) NOT NULL DEFAULT '0'COMMENT '转盘次数',
  `executeturntablecount` int(11) NOT NULL DEFAULT '0'COMMENT '转盘次数',
  `acquiredturntablecfgids` varchar(128) NOT NULL DEFAULT '' COMMENT '已获取的转盘Id',
  `endtime` bigint(20) NOT NULL DEFAULT '0'COMMENT '幸运转盘结束时间',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_iteminfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `items` varchar(10240) NOT NULL DEFAULT '' COMMENT '拥有道具列表',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_seasoninfo` (
  `roleid` bigint(20) NOT NULL COMMENT '角色id',
  `leaguexp` bigint(20) NOT NULL DEFAULT '0'COMMENT '联赛经验',
  `seasonid` int(11) NOT NULL DEFAULT '0'COMMENT '当前赛季',
  `receiveseadonjourneyrecord` varchar(1024) NOT NULL DEFAULT '' COMMENT '赛季征程领取记录',
  `seasonmedaltimeindex` int(11) NOT NULL DEFAULT '0'COMMENT '排行时间下标',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*----------------管理器相关表----------------*/

CREATE TABLE IF NOT EXISTS `orderinfo` (
  `hash` varchar(128) NOT NULL COMMENT 'Hash(钱包交易详情)',
  `lt` bigint(20) NOT NULL DEFAULT '0'COMMENT '交易时间',
  `value` bigint(20) NOT NULL DEFAULT '0'COMMENT '交易价格',

  `gameorderhash` varchar(128) NOT NULL DEFAULT ''COMMENT '玩家订单Hash(游戏自定义)',
  `gameaccount` varchar(128) NOT NULL DEFAULT ''COMMENT '玩家账号(游戏自定义)',
  `gameshopid` int(11) NOT NULL DEFAULT '0'COMMENT '玩家交易商品Id(游戏自定义)',
  `gameshopvalue` bigint(20) NOT NULL DEFAULT '0'COMMENT '玩家交易商品价格(游戏自定义)',
  `gameshopcount` int(11) NOT NULL DEFAULT '0'COMMENT '玩家交易商品数量(游戏自定义)',
  `cryptocointype` varchar(32) NOT NULL DEFAULT '' COMMENT '虚拟币类型',

  `error` smallint(6) NOT NULL DEFAULT '0' COMMENT '交易是否有误',
  `otherinfo` varchar(4096) NOT NULL DEFAULT ''COMMENT '其他信息',
  PRIMARY KEY (`hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `gameorderinfo` (
  `gameorderhash` varchar(128) NOT NULL COMMENT '玩家订单Hash(游戏自定义)',
  `gameaccount` varchar(128) NOT NULL DEFAULT ''COMMENT '玩家账号(游戏自定义)',
  `gameshopid` int(11) NOT NULL DEFAULT '0'COMMENT '玩家交易商品Id(游戏自定义)',
  `gameshopcount` int(11) NOT NULL DEFAULT '0'COMMENT '玩家交易商品数量(游戏自定义)',
  `time` bigint(20) NOT NULL DEFAULT '0' COMMENT '交易时间',
  `transactionplatformenum` smallint(6) NOT NULL DEFAULT '0' COMMENT '交易平台枚举',
  `cryptocointype` varchar(32) NOT NULL DEFAULT '' COMMENT '虚拟币类型',
  `value` bigint(20) NOT NULL DEFAULT '0'COMMENT '交易价格',

  `error` smallint(6) NOT NULL DEFAULT '0' COMMENT '交易是否有误',
  PRIMARY KEY (`gameorderhash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `twitterinfo` (
  `account` varchar(128) NOT NULL,
  `twitterid` varchar(128) NOT NULL DEFAULT '' COMMENT 'twitter用户Id',
  `twitterusername` varchar(128) NOT NULL DEFAULT '' COMMENT 'twitter用户账号名字',
  `twittername` varchar(128) NOT NULL DEFAULT '' COMMENT 'twitter用户昵称',
  `twitteraccesstoken` varchar(256) NOT NULL DEFAULT '' COMMENT 'twitter访问权限token',
  `twitterrefreshtoken` varchar(256) NOT NULL DEFAULT '' COMMENT 'twitter访问权限刷新token',

  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `aeonorderinfo` (
  `merchantorderno` varchar(64) NOT NULL,
  `orderno` varchar(64) NOT NULL DEFAULT '0',
  `orderstatus` varchar(32) NOT NULL DEFAULT '0',
  `iscallback` int(11) NOT NULL DEFAULT '0',

  `gameaccount` varchar(128) NOT NULL DEFAULT ''COMMENT '玩家账号(游戏自定义)',
  `gameshopid` int(11) NOT NULL DEFAULT '0'COMMENT '玩家交易商品Id(游戏自定义)',
  `gameshopvalue` bigint(20) NOT NULL DEFAULT '0'COMMENT '玩家交易商品价格(游戏自定义)',
  `gameshopcount` int(11) NOT NULL DEFAULT '0'COMMENT '玩家交易商品数量(游戏自定义)',
  `time` bigint(20) NOT NULL DEFAULT '0' COMMENT '交易时间',
  `cryptocointype` varchar(32) NOT NULL DEFAULT '' COMMENT '虚拟币类型',

  `error` smallint(6) NOT NULL DEFAULT '0' COMMENT '交易是否有误',
  `otherinfo` varchar(4096) NOT NULL DEFAULT ''COMMENT '其他信息',
  PRIMARY KEY (`merchantOrderNo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

 /*CREATE TABLE IF NOT EXISTS `orderinfo_infura` (
   `orderhash` varchar(128) NOT NULL COMMENT '订单Hash',
   `roleid` bigint(20) NOT NULL COMMENT '角色id',
   `orderstate` smallint(6) NOT NULL DEFAULT '0' COMMENT '订单状态',
   `ordertypeenum` smallint(6) NOT NULL DEFAULT '0' COMMENT '订单类型枚举',
   `iteminstids` varchar(1024) NOT NULL DEFAULT '' COMMENT '订单对应类型物品实例Id列表',
   `time` bigint(20) NOT NULL DEFAULT '0' COMMENT '订单时间',
   `orderreceiptinfo` varchar(2048) NOT NULL DEFAULT '' COMMENT '订单发票信息',
   `orderdetailinfo` varchar(2048) NOT NULL DEFAULT '' COMMENT '订单详情信息',
   `orderfailedverifiedcauseenum` smallint(6) NOT NULL DEFAULT '0' COMMENT '订单验证失败原因枚举',
   PRIMARY KEY (`orderhash`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8;*/


/*----------------后续添加字段----------------*/
/*
ALTER TABLE `role_energyinfo`  
ADD COLUMN `isinitenergy` smallint(6) NOT NULL DEFAULT '0' COMMENT '是否初始化了体力';
ALTER TABLE `role_energyinfo`  
ADD COLUMN `isinitpveitem` smallint(6) NOT NULL DEFAULT '0' COMMENT '是否初始化了Pve道具数量';
ALTER TABLE `role_shopinfo`  
ADD COLUMN `firstshopbuyrecord` varchar(1024) NOT NULL DEFAULT '' COMMENT '首充购买记录';
ALTER TABLE `role_mapinfo`  
ADD COLUMN `winningstreaks` varchar(1024) NOT NULL DEFAULT '' COMMENT '连胜次数';
ALTER TABLE `role_baseinfo`  
ADD COLUMN `totalreceivetoken` bigint(20) NOT NULL DEFAULT '0' COMMENT '总领取token数';
ALTER TABLE `globalinfo`  
ADD COLUMN `seasonid` int(11) NOT NULL DEFAULT '0'COMMENT '赛季Id';
ALTER TABLE `role_mapinfo`  
ADD COLUMN `maphistorydatas` varchar(10240) NOT NULL DEFAULT '' COMMENT '历史记录';
ALTER TABLE `role_mapinfo`  
ADD COLUMN `totalmedalcounts` varchar(128) NOT NULL DEFAULT '' COMMENT '总奖牌数量';
ALTER TABLE `role_mapinfo`  
ADD COLUMN `weekmedalcounts` varchar(128) NOT NULL DEFAULT '' COMMENT '周奖牌数量';
ALTER TABLE `globalinfo`  
ADD COLUMN `seasonstateenum` smallint(6) NOT NULL DEFAULT '0'COMMENT '赛季状态';
ALTER TABLE `globalinfo`  
ADD COLUMN `changenextstatetime` bigint(20) NOT NULL DEFAULT '0' COMMENT '切换赛季状态时间戳';
ALTER TABLE `role_seasoninfo`  
ADD COLUMN `receiveseadonjourneyrecord` varchar(1024) NOT NULL DEFAULT '' COMMENT '赛季征程领取记录';
ALTER TABLE `role_seasoninfo`  
ADD COLUMN `seasonmedaltimeindex` int(11) NOT NULL DEFAULT '0'COMMENT '排行时间下标';
ALTER TABLE `globalinfo`  
ADD COLUMN `seasonmedaltimeindex` int(11) NOT NULL DEFAULT '0'COMMENT '排行时间下标';
*/
ALTER TABLE `role_inviteinfo`  
ADD COLUMN `rebaterecord` varchar(5120) NOT NULL DEFAULT '' COMMENT '返佣记录';
ALTER TABLE `gameorderinfo`  
ADD COLUMN `value` bigint(20) NOT NULL DEFAULT '0'COMMENT '交易价格';
ALTER TABLE `role_baseinfo`  
ADD COLUMN `usdt` bigint(20) NOT NULL DEFAULT '0' COMMENT '消费USDT记录';
ALTER TABLE `role_baseinfo`  
ADD COLUMN `ton` bigint(20) NOT NULL DEFAULT '0' COMMENT '消费TON记录';
ALTER TABLE `role_inviteinfo`  
ADD COLUMN `receiverewardrecord` varchar(5120) NOT NULL DEFAULT '' COMMENT '领取记录';