/*
Navicat MySQL Data Transfer

Source Server         : 140.143.155.252
Source Server Version : 50173
Source Host           : 140.143.155.252:3306
Source Database       : commercialdb

Target Server Type    : MYSQL
Target Server Version : 50173
File Encoding         : 65001

Date: 2018-06-05 14:12:04
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for account_login
-- ----------------------------
DROP TABLE IF EXISTS `account_login`;
CREATE TABLE `account_login` (
  `account_id` varchar(128) NOT NULL,
  `role_id` char(32) NOT NULL,
  `event_type` smallint(6) NOT NULL DEFAULT '0' COMMENT '1：登录，0：登出',
  `update_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '更新时间'
) ENGINE=MyISAM AUTO_INCREMENT=25 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `task_log`;
CREATE TABLE `task_log` (
  `account_id` varchar(128) NOT NULL,
  `role_id` char(32) NOT NULL,
  `task_id` smallint(6) NOT NULL DEFAULT '0' COMMENT '',
  `update_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '更新时间'
) ENGINE=MyISAM AUTO_INCREMENT=25 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `map_log`;
CREATE TABLE `map_log` (
  `account_id` varchar(128) NOT NULL,
  `role_id` char(32) NOT NULL,
  `map_id` smallint(6) NOT NULL DEFAULT '0' COMMENT '',
  `rank_num` smallint(6) NOT NULL DEFAULT '0' COMMENT '',
  `finish_time` int(10) NOT NULL DEFAULT '0' COMMENT '',
  `update_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '更新时间'
) ENGINE=MyISAM AUTO_INCREMENT=25 DEFAULT CHARSET=utf8;