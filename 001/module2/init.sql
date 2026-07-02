-- Module 2 RDS users 테이블 + 채점(6-3)용 데이터
-- terraform apply 후, 프라이빗 서브넷에 접근 가능한 환경(예: bastion / CloudShell + VPC)에서
-- RDS 또는 RDS Proxy 엔드포인트로 접속하여 실행한다.
--   mysql -h <proxy-endpoint> -u admin -p
CREATE DATABASE IF NOT EXISTS wsc2026;
USE wsc2026;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  role VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 채점 6-3 (read test_user → role viewer) 통과용 시드 데이터
INSERT INTO users (username, role) VALUES ('test_user', 'viewer')
  ON DUPLICATE KEY UPDATE role = VALUES(role);
