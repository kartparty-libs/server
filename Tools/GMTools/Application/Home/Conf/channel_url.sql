/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50051
Source Host           : localhost:3306
Source Database       : gmtools_360

Target Server Type    : MYSQL
Target Server Version : 50051
File Encoding         : 65001

Date: 2017-05-23 14:37:22
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `channel_url`
-- ----------------------------
DROP TABLE IF EXISTS `channel_url`;
CREATE TABLE `channel_url` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) default NULL,
  `gm_url` varchar(256) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=38 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of channel_url
-- ----------------------------
INSERT INTO `channel_url` VALUES ('1', '360youxi', 'http://admin.jxbqp.g.yx-g.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('2', '360wan', 'http://admin.w360.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('3', 'duowan', 'http://admin.duowanclouds.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('4', '2217', 'http://admin.2217.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('5', '顺网', 'http://admin.swjoy.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('6', '搜狗', 'http://admin.sogou.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('7', '飞火', 'http://admin.feihuo.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('8', '迅雷', 'http://admin.xunlei.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('9', '游族', 'http://admin.youzu.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('10', '51', 'http://admin.51.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('11', '9377', 'http://admin.9377.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('12', 'G2', 'http://admin.game2.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('13', '2144', 'http://admin.2144.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('14', 'PPS', 'http://admin.pps.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('15', '602', 'http://admin.602.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('16', 'yaodou', 'http://admin.yaodou.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('17', 'yilewan', 'http://admin.yilewan.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('18', 'ku25', 'http://admin.ku25.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('19', '快玩', 'http://admin.teeqee.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('20', 'v1game', 'http://admin.v1game.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('21', '7k7k', 'http://admin.youxi567.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('22', '8090', 'http://admin.8090.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('23', '360uu', 'http://admin.360uu.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('24', '511wan', 'http://admin.511wan.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('25', '37wan', 'http://admin.37wan.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('26', '紫霞', 'http://admin.zixia.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('27', '7u6u', 'http://admin.7u6u.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('28', '501wan', 'http://admin.501wan.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('29', '炫彩', 'http://admin.chinagames.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('30', '酷狗', 'http://admin.17kxgame.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('31', '07329', 'http://admin.07329.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('32', '43u', 'http://admin.43u.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('33', '29yx', 'http://admin.29yx.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('34', 'uc669', 'http://admin.uc669.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('35', 'yx58', 'http://admin.yx58.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('36', '7quwan', 'http://admin.7quwan.jxbqp.ate.cn/php/gmtools.php');
INSERT INTO `channel_url` VALUES ('37', 'kukewan', 'http://admin.kukewan.jxbqp.ate.cn/php/gmtools.php');
