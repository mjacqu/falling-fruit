DATETIME = $(shell date +%Y%m%d%H%M%S)

bounce:
	git pull
	bundle install
	bundle --deployment
	bundle exec rake db:migrate
	sudo chmod -R 777 tmp
	bundle exec rake assets:precompile
	sudo chown -R www-data:www-data tmp
	sudo /etc/init.d/thin restart -C /etc/thin1.9.1/fallingfruit.yml

export:
	#cp export_csv.sql /tmp/
	#sudo su postgres -c "psql -f /tmp/export_csv.sql fallingfruit_db"
	#cp /tmp/ff.csv.bz2 public/data.csv.bz2
	time bundle exec rake export:data
	rm -f public/data.csv.bz2
	bzip2 public/data.csv

clusters:
	bundle exec rake db:migrate:redo VERSION=20131110213005

devserver:
	bundle exec thin -e development start

syncfrombackup:
	scp erichtho:/var/www/falling-fruit/db/backups/fallingfruit.1.sql ./
	bash util/load_backup.sh fallingfruit.1.sql

shapes:
	pgsql2shp -u fallingfruit_user -h localhost -f $(DATETIME)_cluster_polygon.shp fallingfruit_db 'SELECT zoom, muni, count, created_at, updated_at, ST_TRANSFORM(ST_SETSRID(polygon,900913),4326) FROM clusters ORDER BY zoom ASC, muni ASC'
		pgsql2shp -u fallingfruit_user -h localhost -f $(DATETIME)_cluster_point.shp fallingfruit_db 'SELECT zoom, muni, count, created_at, updated_at, ST_TRANSFORM(ST_SETSRID(cluster_point,900913),4326) FROM clusters ORDER BY zoom ASC, muni ASC'
	pgsql2shp -u fallingfruit_user -h localhost -f $(DATETIME)_grid_point.shp fallingfruit_db 'SELECT zoom, muni, count, created_at, updated_at, ST_TRANSFORM(ST_SETSRID(grid_point,900913),4326) FROM clusters ORDER BY zoom ASC, muni ASC'
