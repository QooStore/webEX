package sec03.brd01;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

public class BoardDAO {
	private DataSource dataFactory;
	Connection conn;
	PreparedStatement pstmt;

	public BoardDAO() {
		try {
			Context ctx = new InitialContext();
			Context envContext = (Context) ctx.lookup("java:/comp/env");
			dataFactory = (DataSource) envContext.lookup("jdbc/oracle");
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public List selectAllArticles() {
		List articlesList = new ArrayList();
		try {
			conn = dataFactory.getConnection();
			String query = "WITH RECURSIVE board_tree AS (\r\n" + 
					"    SELECT \r\n" + 
					"        1 AS level, \r\n" + 
					"        articleNO, \r\n" + 
					"        parentNO, \r\n" + 
					"        title, \r\n" + 
					"        content, \r\n" + 
					"        imageFileName, \r\n" + 
					"        writedate, \r\n" + 
					"        id,\r\n" + 
					"        CAST(articleNO AS CHAR(100)) AS path \r\n" + 
					"    FROM t_board\r\n" + 
					"    WHERE parentNO = 0\r\n" + 
					"    \r\n" + 
					"    UNION ALL\r\n" + 
					"    \r\n" + 
					"    SELECT \r\n" + 
					"        bt.level + 1, \r\n" + 
					"        b.articleNO, \r\n" + 
					"        b.parentNO, \r\n" + 
					"        b.title, \r\n" + 
					"        b.content, \r\n" + 
					"        b.imageFileName, \r\n" + 
					"        b.writedate, \r\n" + 
					"        b.id,\r\n" + 
					"        CONCAT(bt.path, '-', b.articleNO) AS path  \r\n" + 
					"    FROM t_board b\r\n" + 
					"    inner JOIN board_tree bt ON b.parentNO = bt.articleNO\r\n" + 
					")\r\n" + 
					"SELECT \r\n" + 
					"    level, \r\n" + 
					"    articleNO, \r\n" + 
					"    parentNO, \r\n" + 
					"    CONCAT(LPAD(' ', 4 * (level - 1), ' '), title) AS title,  \r\n" + 
					"    content, \r\n" + 
					"    imageFileName, \r\n" + 
					"    writedate, \r\n" + 
					"    id,\r\n" + 
					"    path  \r\n" + 
					"FROM board_tree\r\n" + 
					"ORDER BY path";
			System.out.println(query);
			pstmt = conn.prepareStatement(query);
			ResultSet rs = pstmt.executeQuery();
			while (rs.next()) {
				int level = rs.getInt("level");
				int articleNO = rs.getInt("articleNO");
				int parentNO = rs.getInt("parentNO");
				String title = rs.getString("title");
				String content = rs.getString("content");
				String id = rs.getString("id");
				Date writeDate = rs.getDate("writeDate");
				ArticleVO article = new ArticleVO();
				article.setLevel(level);
				article.setArticleNO(articleNO);
				article.setParentNO(parentNO);
				article.setTitle(title);
				article.setContent(content);
				article.setId(id);
				article.setWriteDate(writeDate);
				articlesList.add(article);
			}
			rs.close();
			pstmt.close();
			conn.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
		return articlesList;
	}
}
