# 🏠 CRM-ERP Data Warehouse Project

This project presents a data warehouse containing both CRM and ERP Data, and ultimately provides analytics/reporting-ready data for end users.

---
## 🧮 Data Source

Data sources are in the form of 6 CSV files containing either CRM or ERP data. They are from the following **[GitHub Repository](https://github.com/DataWithBaraa/sql-data-warehouse-project/blob/main/README.md?plain=1)**.

---
## 📐 Data Architecture

This project's architecture follows the Medallion Architecture, utilizing **🥉 Bronze**, **🥈 Silver**, and **🥇 Gold** layers:

1. **🥉 Bronze Layer**: Stores raw, uncleaned data from CSV files into the Microsoft SQL Server Database.
2. **🥈 Silver Layer**: A clean version of the Bronze Layer. The format of the tables are more or less the same, but data cleaning and standardization have been performed to prepare the data for the Gold layer.
3. **🥇 Gold Layer**: Contains Analytics/Reporting-ready data from the Silver layer through views.

---
## 📚 References

Huge thanks to Data with Baraa for the guidance on this project. Below are his links:

**[YouTube](http://bit.ly/3GiCVUE)**

**[LinkedIn](https://linkedin.com/in/baraa-khatib-salkini)**

**[Website](https://www.datawithbaraa.com)**

