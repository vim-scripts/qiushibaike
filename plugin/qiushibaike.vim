"=============================================================================
"  Author:          DanteZhu - http://www.vimer.cn
"  Email:           dantezhu@vip.qq.com
"  FileName:        qiushibaike.vim
"  Description:     用VIM看糗事百科
"  Version:         1.0
"  LastChange:      2010-05-04 21:08:09
"  History:
"=============================================================================
function! SetBaiKeBuffer()
let bkbuffloaded=bufloaded("baike")
if !bkbuffloaded
	execute "sp baike"
	execute "normal \Z"
else
	while 1
		execute "normal \<c-w>w"
		let currBuff=bufname("%")
		if currBuff == "baike"
			execute "normal \Z"
			break
		endif
	endwhile

endif
endfunction

function! KanXiaoHua(url,page)
call SetBaiKeBuffer()
let b:baikeurl=a:url
let b:baikepage=a:page
if a:page == ""
	let b:currbkpage=1
	let b:baikeurl=b:baikeurl."/page/".b:currbkpage
else
	let b:currbkpage=b:currbkpage+1
	let b:baikeurl=b:baikeurl."/page/".b:currbkpage
endif
python << EOF

import vim
import time
import urllib
import urllib2
from BeautifulSoup import BeautifulSoup

def getBaiKe():
	url=vim.eval("b:baikeurl")
	user_agent = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)'
	values = {'name' : 'DanteZhu',
		'location' : 'China',
		'language' : 'Python' }
	headers = { 'User-Agent' : user_agent }

	data = urllib.urlencode(values)
	req = urllib2.Request(url, data, headers)
	response = urllib2.urlopen(req)
	the_page = response.read()
	soup = BeautifulSoup(the_page)

	allTags = soup.findAll(attrs={'class' : 'qiushi_body article'})
	for tag in allTags:
		vim.current.buffer.append("\n")
		for art in tag.contents:
			if isinstance(art,basestring) != True:
				continue
			tmpStr=art.encode(vim.eval("&encoding")).replace("&nbsp;",' ')
			tmpStr=tmpStr.replace("",'')
			tmpStr=tmpStr.replace("&quot;",'"')
			strList=tmpStr.split("\n")   
			for line in strList:   
				if len(line) > 0:
					vim.current.buffer.append(line)   
		vim.current.buffer.append("\n")
		vim.current.buffer.append('#=============================================================================')


vim.current.buffer[:]=None
getBaiKe()
EOF
exe "set wrap"
exe 'syn match      qbSplit	"^\s*\zs#.*$"'
"exe 'syn match      qbSplit	"\s\zs#.*$"'
exe 'hi def link qbSplit		Comment'
endfunction

command! -nargs=0 JOKE :call KanXiaoHua("http://www.qiushibaike.com/groups/2/latest","")
command! -nargs=0 NEXTJOKE :call KanXiaoHua("http://www.qiushibaike.com/groups/2/latest","N")
command! -nargs=0 BESTJOKE :call KanXiaoHua("http://www.qiushibaike.com/groups/2/hottest/day","")
command! -nargs=0 NEXTBESTJOKE :call KanXiaoHua("http://www.qiushibaike.com/groups/2/hottest/day","N")
