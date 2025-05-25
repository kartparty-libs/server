SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE IF NOT EXISTS `globalinfo` (
  `serverid` int(11) NOT NULL,
  `opentime` bigint(20) NOT NULL DEFAULT '0' COMMENT '服务器创建时间戳',
  PRIMARY KEY (`serverid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `login_roleinfo` (  
  `account` varchar(128) NOT NULL,  
  `serverid` int(11) NOT NULL,  
  `ip` varchar(128) NOT NULL COMMENT '首次登入Ip',  
  PRIMARY KEY (`account`),  
  KEY `role_account_index` (`account`) USING BTREE  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `login_walletinfo` (      
  `id` int AUTO_INCREMENT PRIMARY KEY,    
  `wallethash` varchar(128) NOT NULL,    
  `account` varchar(128) NOT NULL,    
  `walletname` varchar(24) NOT NULL,    
  KEY `role_wallethash_index` (`wallethash`) USING BTREE,  
  KEY `role_account_index` (`account`) USING BTREE,
  KEY `role_walletname_index` (`walletname`) USING BTREE  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `login_tgbotinfo` (  
  `account` varchar(128) NOT NULL,  
  `source` varchar(128) NOT NULL DEFAULT '' COMMENT '来源',  
  `iscreateplayer` smallint(6) NOT NULL DEFAULT '0' COMMENT '是否创建玩家',
  `time` bigint(20) NOT NULL DEFAULT '0' COMMENT '时间戳',
  PRIMARY KEY (`account`),  
  KEY `role_account_index` (`account`) USING BTREE  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `login_rebateinfo` (  
  `rebatekey` varchar(256) NOT NULL,
  `serverid` int(6) NOT NULL DEFAULT '0' COMMENT '服务器Id',
  `account` varchar(128) NOT NULL DEFAULT '' COMMENT '玩家账号',  
  `time` bigint(20) NOT NULL DEFAULT '0' COMMENT '申请时间戳',
  `cryptoenum` smallint(6) NOT NULL DEFAULT '-1' COMMENT '虚拟币枚举',
  `address` varchar(256) NOT NULL DEFAULT '' COMMENT '钱包地址',  
  `network` varchar(32) NOT NULL DEFAULT '' COMMENT '加密货币',  
  `withdrawalamount` bigint(20) NOT NULL DEFAULT '0' COMMENT '取款金额',
  `networkfee` bigint(20) NOT NULL DEFAULT '0' COMMENT '手续费',
  `receiveamount` bigint(20) NOT NULL DEFAULT '0' COMMENT '收到金额',
  `memo` varchar(256) NOT NULL DEFAULT '' COMMENT '备注',  
  `state` smallint(6) NOT NULL DEFAULT '0' COMMENT '状态',
  PRIMARY KEY (`rebatekey`),  
  KEY `key_index` (`rebatekey`) USING BTREE  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*----------------后续添加字段----------------*/

 /*
 ALTER TABLE `login_rebateinfo`  
ADD COLUMN `cryptoenum` smallint(6) NOT NULL DEFAULT '-1' COMMENT '虚拟币枚举';
 ALTER TABLE `login_tgbotinfo`  
ADD COLUMN `time` bigint(20) NOT NULL DEFAULT '0' COMMENT '时间戳';
*/