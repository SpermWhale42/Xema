
#include <iostream>
#include <string>
#include "istream"
#include <fstream> 
#include <vector>
#include <sstream>

std::string &StringTrim(std::string &str);
std::vector<std::string> vStringSplit(const std::string &s, const std::string &delim);

struct SystemConfigParam
{
	//投影亮度
	int led_current;
	//曝光次数
	int exposure_num;
	//曝光参数
	int exposure_param[6];
	//相机曝光时间（us）
	float camera_exposure_time;
	//相机增益DB
	float camera_gain;
	//外参标识:1-相机、2-光机、3-外部标定板。
	int external_param_flag;
	//相机外参
	float external_param[12];
	//基准平面
	float standard_plane[4];

};

struct SystemConfigDataStruct
{
	SystemConfigDataStruct();

	SystemConfigParam config_param_;
  
	bool loadFromSettings(const std::string& f);
	bool saveToSettings(const std::string& f);
 
	static SystemConfigDataStruct& Instance()
	{
		return instance_;
	}

private:
	static SystemConfigDataStruct instance_;
};

