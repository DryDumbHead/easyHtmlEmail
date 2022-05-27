# easyHtmlEmail changelog

## [0.1.2] - 11 Feb 2022
* Add attachments as text file, implicit conversion will be done when string is passed : method add_attachment
* Replace Placeholder by HTML &lt;li&gt;  &lt;option&gt; &lt;tr&gt; when REPLACEMENT_TYPE is ' ' or 'T' : method Replace_placeholder 

## [0.1.1] - 21 Dec 2021

### Added 
* Add attachments  
* Ability to handle error by returning cl_bsc from method build_mail()  

### Changed
* Refactored the method send_mail()  

## [0.1.0] - 29 Sept 2021

### Added
* support for Master template to achieve reusability  
* [README.md](README.md), [CHANGELOG.md](CHANGELOG.md), [LICENSE](LICENSE)

## [0.1.0] 
* First public preview
