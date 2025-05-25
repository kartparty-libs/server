SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE IF NOT EXISTS `globalinfo` (
  `serverid` int(11) NOT NULL,
  `opentime` bigint(20) NOT NULL DEFAULT '0' COMMENT '服务器创建时间戳',
  `zerotime` bigint(20) NOT NULL DEFAULT '0' COMMENT '今日凌晨时间',
  `seasonid` int(11) NOT NULL DEFAULT '0'COMMENT '赛季Id',
  `seasonmedaltimeindex` int(11) NOT NULL DEFAULT '0'COMMENT '排行开始时间下标',
  PRIMARY KEY (`serverid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*----------------后续添加字段----------------*/

 /*ALTER TABLE `tablename`  
ADD COLUMN `addtext` VARCHAR(128) DEFAULT NULL COMMENT '添加字段';
ALTER TABLE `globalinfo`  
ADD COLUMN `seasonmedaltimeindex` int(11) NOT NULL DEFAULT '0'COMMENT '排行开始时间下标';
ALTER TABLE `globalinfo`  
ADD COLUMN `seasonid` int(11) NOT NULL DEFAULT '0'COMMENT '赛季Id';*/