const fs = require("fs");
const localFilePath = "./config.local.js";

let databaseConfig = require("./config.database.json");
let tableSchema = "JFW";

/* Table names to include in the generation */
let includedEntityList = [];
let excludedEntityList = ["LOG4NET"];

/* Available template suffixes - (EntityClasses)
 * - .Constants
 * - .
 * - .Exceptions
 * - .Errors
 * - .Overrides
 * - .Validations
 */
let includedCoreSuffixList = [];
let excludedCoreSuffixList = [];
const configToggles = {
  shouldGenerateDataAccess: true,
  shouldGenerateRepository: true,
  shouldGenerateCoreModels: true,
  shouldGenerateEntityClasses: true,
  shouldGenerateEntityModels: true,
  shouldGenerateMemoryClasses: false,
};

if (fs.existsSync(localFilePath)) {
  const localConfig = require(localFilePath);

  // Override default values
  if (localConfig.database) {
    databaseConfig = localConfig.database;
  }

  if (localConfig.tableSchema) {
    tableSchema = localConfig.tableSchema;
  }

  if (localConfig.includedEntityList) {
    includedEntityList = localConfig.includedEntityList;
  }

  if (localConfig.excludedEntityList) {
    excludedEntityList = localConfig.excludedEntityList;
  }

  if (localConfig.includedCoreSuffixList) {
    includedCoreSuffixList = localConfig.includedCoreSuffixList;
  }

  if (localConfig.excludedCoreSuffixList) {
    excludedCoreSuffixList = localConfig.excludedCoreSuffixList;
  }

  if (localConfig.toggles) {
    for (const key in localConfig.toggles) {
      configToggles[key] = localConfig.toggles[key];
    }
  }

  console.log("Local configuration loaded.");
}

// SQL Server data types to C# data types
const sqlDataTypeMapping = {
  bigint: "long",
  binary: "byte[]",
  bit: "bool",
  char: "string",
  date: "DateTime",
  datetime: "DateTime",
  datetime2: "DateTime",
  datetimeoffset: "DateTimeOffset",
  decimal: "decimal",
  float: "double",
  image: "byte[]",
  int: "int",
  money: "decimal",
  nchar: "string",
  ntext: "string",
  numeric: "decimal",
  nvarchar: "string",
  real: "float",
  rowversion: "byte[]",
  smalldatetime: "DateTime",
  smallint: "short",
  smallmoney: "decimal",
  text: "string",
  time: "TimeSpan",
  timestamp: "byte[]",
  tinyint: "byte",
  uniqueidentifier: "Guid",
  varbinary: "byte[]",
  varchar: "string",
  xml: "string",
};

const tableDictionaryPath = {
  Address: "system-configuration",
  AppSettingSmtp: "system-configuration",
  BlackList: "system-configuration",
  Brand: "brand",
  BrandEmail: "brand",
  BrandLink: "brand",
  BrandProfile: "brand",
  BrandSetting: "brand",
  Cdn: "system-configuration",
  City: "system-definition",
  Configuration: "system-configuration",
  Country: "system-definition",
  Coupon: "coupon",
  CouponUser: "coupon",
  Currency: "system-definition",
  Device: "device",
  DeviceProfile: "device",
  DeviceSetting: "device",
  ExternalAuthenticationProvider: "system-configuration",
  ExternalAuthenticationProviderUser: "system-configuration",
  ExchangeRate: "system-configuration",
  Feature: "pricing",
  HelpDesk: "tracking",
  HelpDeskFeedback: "tracking",
  HelpDeskFeedbackAttachment: "tracking",
  Language: "system-definition",
  License: "license",
  Package: "pricing",
  PackageFeature: "",
  Payment: "payment",
  PaymentHistory: "payment",
  PaymentMethod: "payment",
  PaymentProvider: "system-configuration",
  Permission: "role-right",
  Point: "point",
  PointEvent: "point",
  PointHistory: "point",
  PointReward: "point",
  Price: "pricing",
  Role: "role-right",
  RolePermission: "",
  State: "system-definition",
  SubscriptionType: "pricing",
  TimeZone: "system-definition",
  TrackingActivity: "tracking",
  TrackingEmail: "tracking",
  TrackingEmailPattern: "tracking",
  TrackingEmailRead: "tracking",
  TrackingEvent: "tracking",
  TrackingNotification: "tracking",
  TrackingNotificationRead: "tracking",
  User: "user",
  UserAddress: "user",
  UserProfile: "user",
  UserRole: "user",
  UserSetting: "user",
  UserWallet: "payment",
};

module.exports = {
  databaseConfig: databaseConfig.server,
  tableSchema,
  sqlDataTypeMapping,
  includedEntityList,
  excludedEntityList,
  includedCoreSuffixList,
  excludedCoreSuffixList,
  tableDictionaryPath,
  configToggles,
};
