# Install gdal 1.10 or newer and compile using the following:
# ./configure --with-spatialite=yes --with-expat=yes --with-python=yes
# Without it, the OSM format will not be enabled.

# Install latest osmosis to get the read-pbf-fast command. older versions
# like the one shipped with Ubuntu 14.04 do not have this option.

# Once you have them, make sure gdal/apps and osmosis/bin are added to our path before running this file.
ifeq ($(URL),)
abort:
	@echo Variable URL not set && false
endif

ifeq ($(NAME),)
abort:
	@echo Variable NAME not set && false
endif

ifeq ($(DB_USER),)
abort:
	@echo Variable DB_USER not set && false
endif

ifeq ($(DB_PASS),)
abort:
	@echo Variable DB_PASS not set && false
endif

ifeq ($(VENV_PATH),)
abort:
	@echo Variable VENV_PATH not set && false
endif


DB=osm_$(NAME)
SETNAME=$(NAME)

mk-work-dir:
	mkdir -p ./$(NAME)

latest.pbf: mk-work-dir
	curl -g -o $(NAME)/$@.temp $(URL)
	if file $(NAME)/$@.temp | grep XML; then \
        osmosis --read-xml file="$(NAME)/$@.temp" --write-pbf file="$(NAME)/$@"; \
    else \
        mv $(NAME)/$@.temp $(NAME)/$@; \
    fi

aerodromes_point.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --nkv keyValueList="aeroway.aerodrome" --write-pbf file="$(NAME)/$@"

aerodromes_polygon.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<"  --wkv keyValueList="aeroway.aerodrome" --used-node --write-pbf file="$(NAME)/$@"

all_places.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --nkv keyValueList="place.city,place.borough,place.suburb,place.quarter,place.neighbourhood,place.city_block,place.plot,place.town,place.village,place.hamlet,place.isolated_dwelling,place.farm,place.allotments" --tf reject-ways --tf reject-relations --write-pbf file="$(NAME)/$@"

all_roads.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<"  --tf accept-ways "highway=*" --used-node --write-pbf file="$(NAME)/$@"

banks.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --tf accept-nodes amenity=bank,atm,bureau_de_change --tf reject-ways --tf reject-relations --write-pbf file="$(NAME)/$@"

buildings.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<"  --tf accept-ways "building=*"  --write-pbf file="$(NAME)/$@"

built_up_areas.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --tf accept-ways landuse=residential,allotments,cemetery,construction,depot,garages,brownfield,commercial,industrial,retail --used-node --write-pbf file="$(NAME)/$@"

cities.pbf: all_places.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<"  --tf accept-nodes "place=city" --tf reject-ways --tf reject-relations --write-pbf file="$(NAME)/$@"

farms.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --wkv keyValueList="landuse.farm,landuse.farmland,landuse.farmyard,landuse.livestock" --used-node --write-pbf file="$(NAME)/$@"

forest.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --wkv keyValueList="landuse.forest,natural.wood" --used-node --write-pbf file="$(NAME)/$@"

grassland.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --wkv keyValueList="landuse.grass,landuse.meadow,landuse.scrub,landuse.village_green,natural.scrub,natural.heath,natural.grassland" --used-node --write-pbf file="$(NAME)/$@"

helipads.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --tf accept-nodes aeroway=helipad,heliport --tf reject-ways --tf reject-relations --write-pbf file="$(NAME)/$@"

hotels.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --nkv keyValueList="tourism.hotel,tourism.hostel,tourism.motel,tourism.guest_house" --tf reject-ways --tf reject-relations --write-pbf file="$(NAME)/$@"

inland_water_line.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" \
	--tf reject-relations --tf accept-ways waterway=* --used-node \
	--write-pbf file="$(NAME)/$@"

inland_water_polygon.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" \
	--tf accept-ways natural=water,wetland,bay landuse=reservoir,basin,salt_pond waterway=river,riverbank \
	--tf accept-relations natural=water,wetland,bay landuse=reservoir,basin,salt_pond waterway=river,riverbank \
	--used-node	--write-pbf file="$(NAME)/$@"

main_roads.pbf: all_roads.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --wkv keyValueList="highway.motorway,highway.trunk,highway.primary" --used-node --write-pbf file="$(NAME)/$@"

medical_point.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --nkv keyValueList="amenity.baby_hatch,amenity.clinic,amenity.dentist,amenity.doctors,amenity.hospital,amenity.nursing_home,amenity.pharmacy,amenity.social_facility,amenity.veterinary,amenity.blood_donation" --write-pbf file="$(NAME)/$@"

medical_polygon.pbf: buildings.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --wkv keyValueList="amenity.baby_hatch,amenity.clinic,amenity.dentist,amenity.doctors,amenity.hospital,amenity.nursing_home,amenity.pharmacy,amenity.social_facility,amenity.veterinary,amenity.blood_donation" --used-node --write-pbf file="$(NAME)/$@"

paths.pbf: all_roads.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --wkv keyValueList="highway.footway,highway.bridleway,highway.steps,highway.path" --used-node  --write-pbf file="$(NAME)/$@"

police_stations.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --nkv keyValueList="amenity.police" --tf reject-ways --tf reject-relations  --write-pbf file="$(NAME)/$@"

railways.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --tf accept-ways "railway=*" --used-node --write-pbf file="$(NAME)/$@"

schools_point.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" \
	--nkv keyValueList="amenity.school,amenity.university,amenity.college,amenity.kindergarten,amenity.library,amenity.public_bookcase,amenity.music_school,amenity.driving_school,amenity.language_school" \
	--write-pbf file="$(NAME)/$@"

schools_polygon.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" \
	--wkv keyValueList="amenity.school,amenity.university,amenity.college,amenity.kindergarten,amenity.library,amenity.public_bookcase,amenity.music_school,amenity.driving_school,amenity.language_school" \
	--used-node --write-pbf file="$(NAME)/$@"

towns.pbf: all_places.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<"  --tf accept-nodes "place=town" --tf reject-ways --tf reject-relations  --write-pbf file="$(NAME)/$@"

tracks.pbf: all_roads.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<"  --wkv keyValueList="highway.track" --used-node --write-pbf file="$(NAME)/$@"

transport_point.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" \
	--tf accept-nodes amenity=bicycle_parking,bicycle_repair_station,bicycle_rental,boat_sharing,bus_station,car_rental,car_sharing,car_wash,charging_station,ferry_terminal,fuel,grit_brin,motorcycle_parking,parking,parking_entrance,parking_space,taxi \
	public_transport=* railway=halt,station,subway_entrance,tram_stop waterway=dock,boatyard \
	--tf reject-ways --tf reject-relations  --write-pbf file="$(NAME)/$@"

utilities.pbf: latest.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<" --tf reject-ways --tf reject-relations \
	--tf accept-nodes amenity=shower,toilets,water_point,drinking_water,water_in_place \
	--write-pbf file="$(NAME)/$@"

villages.pbf: all_places.pbf
	osmosis --read-pbf-fast file="$(NAME)/$<"  --tf accept-nodes "place=village" --tf reject-ways --tf reject-relations --write-pbf file="$(NAME)/$@"

SHP_EXPORTS = aerodromes_point.shp aerodromes_polygon.shp all_places.shp \
all_roads.shp banks.shp buildings.shp built_up_areas.shp cities.shp farms.shp \
forest.shp grassland.shp helipads.shp hotels.shp inland_water_line.shp \
inland_water_polygon.shp main_roads.shp medical_point.shp medical_polygon.shp \
paths.shp police_stations.shp railways.shp schools_point.shp schools_polygon.shp \
towns.shp tracks.shp transport_point.shp utilities.shp villages.shp

PBF_EXPORTS = $(SHP_EXPORTS:.shp=.pbf)

%.shp: %.pbf
	ogr2ogr -f "ESRI Shapefile" $(NAME)/$@ $(NAME)/$< -lco COLUMN_TYPES=other_tags=hstore --config OSM_CONFIG_FILE conf/$(basename $@).ini

.PHONY: createdb
createdb:
	if PGPASSWORD=$(DB_PASS) psql -U $(DB_USER) -lqt | cut -d \| -f 1 | grep -w $(DB); then \
		echo "Database exists"; \
	else \
		createdb $(DB); \
		PGPASSWORD=$(DB_PASS) psql -U $(DB_USER) -d $(DB) -c 'create extension postgis;'; \
		PGPASSWORD=$(DB_PASS) psql -U $(DB_USER) -d $(DB) -c 'create extension hstore;'; \
	fi

all: createdb $(PBF_EXPORTS) $(SHP_EXPORTS)

.PHONY: clean
clean:
	rm -rf $(NAME)/*.pbf
