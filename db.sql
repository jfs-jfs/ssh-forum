
DROP TABLE IF EXISTS `board`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `board` (
  `id` int NOT NULL AUTO_INCREMENT,
  `link` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(200) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `link` (`link`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;


DROP TABLE IF EXISTS `post`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post` (
  `id` int NOT NULL AUTO_INCREMENT,
  `author` varchar(100) NOT NULL DEFAULT 'Pagan',
  `comment` text NOT NULL,
  `thread_id` int NOT NULL,
  `creation` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `poster_ip` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `thread_id` (`thread_id`),
  CONSTRAINT `post_ibfk_1` FOREIGN KEY (`thread_id`) REFERENCES `thread` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1280 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;


DROP TABLE IF EXISTS `post_ssh`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_ssh` (
  `id` int NOT NULL AUTO_INCREMENT,
  `author` varchar(100) NOT NULL DEFAULT 'Pagan',
  `comment` text NOT NULL,
  `thread_id` int NOT NULL,
  `creation` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `poster_ip` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `thread_id` (`thread_id`),
  CONSTRAINT `postssh_ibfk_1` FOREIGN KEY (`thread_id`) REFERENCES `thread_ssh` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1280 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;


DROP TABLE IF EXISTS `thread`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `thread` (
  `id` int NOT NULL AUTO_INCREMENT,
  `table_id` int NOT NULL,
  `title` varchar(256) DEFAULT NULL,
  `author` varchar(256) NOT NULL DEFAULT 'Pagan',
  `comment` text NOT NULL,
  `creation` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_rp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `poster_ip` varchar(15) DEFAULT NULL,
  `pinned` tinyint(1) NOT NULL DEFAULT '0',
  `replies` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `table_id` (`table_id`),
  CONSTRAINT `thread_ibfk_1` FOREIGN KEY (`table_id`) REFERENCES `board` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;


DROP TABLE IF EXISTS `thread_ssh`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `thread_ssh` (
  `id` int NOT NULL AUTO_INCREMENT,
  `table_id` int NOT NULL,
  `title` varchar(256) DEFAULT NULL,
  `author` varchar(256) NOT NULL DEFAULT 'Pagan',
  `comment` text NOT NULL,
  `creation` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_rp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `poster_ip` varchar(15) DEFAULT NULL,
  `pinned` tinyint(1) NOT NULL DEFAULT '0',
  `replies` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `table_id` (`table_id`),
  CONSTRAINT `threadssh_ibfk_1` FOREIGN KEY (`table_id`) REFERENCES `board` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=186 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
