create database test;
use test;
create table userpass(user varchar(255), pass varchar(255));
create table roles(user varchar(255), role varchar(255));
create table websites(user varchar(255), site varchar(255));
create table votes(user varchar(255), vote1 varchar(255), vote2 varchar(255), vote3 varchar(255));
create table salts(user varchar(255), salt varchar(255));
