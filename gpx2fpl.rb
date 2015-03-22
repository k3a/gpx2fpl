#!/usr/bin/env ruby
# Convert GPX to Garmin FPL
# Created by www.K3A.me, released under GNU GPL

require 'rexml/document'
require 'time'
include REXML

abort "Usage: gpx2fpl <path_to_gpx>" if ARGV.length != 1

def wptype(name)
    return "AIRPORT" if ((name.length == 4 || name.length == 6) && name !~ /[- _,.\/\\0-9]/)
    return "USER WAYPOINT"
end

def wpcountry(name)
    return name[0,2] if wptype(name) == "AIRPORT"
    return ""
end

# input
doc = Document.new( File.new(ARGV[0]) )
root = doc.root

# output
odoc = Document.new()
oroot = odoc.add_element("flight-plan")
oroot.add_attribute("xmlns", "http://www8.garmin.com/xmlschemas/FlightPlan/v1")
oroot.add_element("created").text = Time.now.utc.iso8601
owps = oroot.add_element("waypoint-table")
oroute = oroot.add_element("route")

# get route name
name = root.elements["metadata/name"]
name = root.elements["rte/name"] if !name
name = ["Unnamed"] if !name
name = name.first.to_s
puts "-- #{name} --"

# set route name
oroute.add_element("route-name").text = name
oroute.add_element("flight-plan-index").text = 1

root.each_element("rte/rtept") do |e|
    en = e.elements["name"].first.to_s
    type = wptype(en)
    country = wpcountry(en)
    elat = e.attributes["lat"]
    elon = e.attributes["lon"]
    puts " #{en}: #{elat}, #{elon}"

    wp = owps.add_element("waypoint")
    wp.add_element("identifier").text = en
    wp.add_element("type").text = type
    wp.add_element("ountry-code").text = country
    wp.add_element("lat").text = elat
    wp.add_element("lon").text = elon
    wp.add_element("comment").text = ""

    rp = oroute.add_element("route-point")
    rp.add_element("waypoint-identifier").text = en
    rp.add_element("waypoint-type").text = type
    rp.add_element("waypoint-country-code").text = country
end

# write output
fn = "#{File.dirname(ARGV[0])}/#{File.basename(ARGV[0], ".gpx")}.fpl"
File.open(fn,"w") do |data|
    data << odoc
end


