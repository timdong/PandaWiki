package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

func main() {
	// 从环境变量或默认配置获取数据库连接字符串
	dsn := "host=localhost user=panda-wiki password=panda-wiki-secret dbname=panda-wiki port=5432 sslmode=disable TimeZone=Asia/Shanghai"

	// 提示用户修改连接字符串
	fmt.Println("🔍 正在测试数据库连接...")
	fmt.Println("📝 请确保修改连接字符串中的用户名、密码和数据库名")
	fmt.Printf("🔗 当前连接字符串: %s\n", dsn)
	fmt.Println()

	// 尝试连接数据库
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("❌ 无法打开数据库连接: %v", err)
	}
	defer db.Close()

	// 测试连接
	if err := db.Ping(); err != nil {
		log.Fatalf("❌ 无法连接到数据库: %v", err)
	}

	// 查询PostgreSQL版本
	var version string
	err = db.QueryRow("SELECT version()").Scan(&version)
	if err != nil {
		log.Fatalf("❌ 无法查询数据库版本: %v", err)
	}

	fmt.Println("✅ 数据库连接成功!")
	fmt.Printf("📊 PostgreSQL版本: %s\n", version)

	// 检查是否存在PandaWiki所需的数据库
	var exists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname = $1)", "panda-wiki").Scan(&exists)
	if err != nil {
		fmt.Printf("⚠️  无法检查数据库是否存在: %v\n", err)
	} else if exists {
		fmt.Println("✅ 'panda-wiki' 数据库已存在")
	} else {
		fmt.Println("⚠️  'panda-wiki' 数据库不存在，请创建它")
		fmt.Println("💡 创建命令: CREATE DATABASE \"panda-wiki\" OWNER \"panda-wiki\";")
	}
}
