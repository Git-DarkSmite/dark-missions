CREATE TABLE IF NOT EXISTS `dark-missions` (
  `citizenid` varchar(50) NOT NULL,
  `missionName` varchar(255) NOT NULL,
  `cooldownTime` bigint(20) DEFAULT NULL,
  `done` int(11) DEFAULT NULL,
  PRIMARY KEY (`missionName`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;