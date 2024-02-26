package hello;

import javax.sql.DataSource;

import com.zaxxer.hikari.HikariDataSource;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Profile;

@SpringBootApplication
public class App {

	public static void main(String[] args) {
		SpringApplication.run(App.class, args);
	}

	@Bean
	@Profile({ "jdbc", "jpa" })
	public DataSource datasource(DataSourceProperties dataSourceProperties) {
		HikariDataSource dataSource = dataSourceProperties.initializeDataSourceBuilder().type(HikariDataSource.class)
				.build();
		dataSource.setMaximumPoolSize(Runtime.getRuntime().availableProcessors() * 2);

		return dataSource;
	}
}
