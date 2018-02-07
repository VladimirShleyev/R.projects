#!/usr/bin/python
# -*- coding: cp1251 -*-

# import string, sys, os.path
# import re
import win32com.client
from win32com.client import constants

def main():
 xlOpenXMLWorkbookMacroEnabled = 52
 
 xlApp = win32com.client.Dispatch("Excel.Application")
 xlApp.Visible = True
 xlApp.AskToUpdateLinks = False
 xlApp.EnableEvents = True
 # xlwb = xlApp.Workbooks.Open(r'D:\Temp\1\IT.P-18-99 ���-6.1 (��� �������) v3-unprotected.xlsm')
 # xlwb = xlApp.Workbooks.Open(r'D:\Temp\1\IT.P-18-99 ���-6.1 (��� �������) v3.xlsm')
 xlwb = xlApp.Workbooks.Open(r'D:\Temp\1\11.xlsm')
 sheet = xlwb.Worksheets('������ - ��-���')  #.Select()
 print(sheet.Range("C139").Value)

 # xlwb.SaveAs("D:\\Temp\\1\\res.xls", FileFormat = 56) # http://www.rondebruin.nl/win/s5/win001.htm
 # xlwb.RunAutoMacros("xlAutoClose") # �� �����������
 print(xlwb.ActiveSheet.Name)
 xlwb.Worksheets('��� ��������').Activate
# xlwb.Save()
 xlwb.SaveAs("res.xlsm", FileFormat = "xlOpenXMLWorkbookMacroEnabled", ConflictResolution = "xlLocalSessionChanges")
 xlwb.Close(SaveChanges=1)
    
if __name__ == '__main__':
 print(constants)
 main()
