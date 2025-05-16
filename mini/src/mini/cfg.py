from dataclasses import dataclass
from enum import StrEnum, auto
from pathlib import Path
from textwrap import dedent


class Technology(StrEnum):
    BASH = auto()
    KSH = auto()
    READLINE = auto()
    VIM = auto()


@dataclass
class MiniConfig:
    technology: Technology
    path: Path | None = None
    content: str = ''
    comments: str = '#'
    description: str = ''

    @property
    def conf(self) -> str:
        _cfg = [
            f"cat >> {self.path} << 'EOC'",
            f'{self.comments} {"-" * 78}',  # --------
            self.content,
            'EOC',
        ]
        return '\n'.join(_cfg)


vimrc_oneline = MiniConfig(
    technology=Technology.VIM,
    content=dedent(
        r"""
        " mnemo :-D
        " ces culs nus hide (cachent) les 2 mosaïques
        se cul nu hid ls=2 mouse=a ic | colo slate
        """
    ),
    comments='"',
)


vimrc = MiniConfig(
    technology=Technology.VIM,
    path=Path('~/.vimrc'),
    content=r'se nocp wb bsk= noaw noawa noar is hls ic scs inf isf-== nu nuw=1 sm mat=2 mps+=<:> cf sc report=0 shm=flmnrxoOtT dy+=lastline lz so=2 tsl=3 tm=2000 ttm=100 vb t_vb= lbr sbr=\\\  lcs=tab:>-,trail:-,nbsp:- t_Co=256 smc=301 mouse=a ttym=xterm2 fo+=ron nojs ai ts=8 sts=4 et sw=4 sr cpt-=t cot-=preview sft hid dip+=vertical noea spr swb=useopen wmnu wim=full wig+=*~,*.swp,tags ru ls=2 bs=2 ve=block,insert,onemore ww=b,s,<,>,[,] para= nosol nf-=octal bg=dark | nn <c-l> :nohls<cr><c-l> | sy on | colo delek | hi Comment ctermfg=121 | hi LineNr ctermfg=8 | filet plugin indent on',
    comments='"',
)

inputrc = MiniConfig(
    technology=Technology.READLINE,
    path=Path('~/.inputrc'),
    content=dedent(
        r"""# GNU Readline Library
        # http://cnswww.cns.cwru.edu/php/chet/readline/rluserman.html
        #
        # Note: use ^x^r to re-read this file after modification

        # <up> and <down>
        "\e[A": history-search-backward
        "\e[B": history-search-forward

        # Ctrl-A, Ctrl-E
        # <home> and <end>
        "\e[1~": beginning-of-line
        "\e[4~": end-of-line
        # <ctrl-left> and <ctrl-right>
        "\e[1;5D": beginning-of-line
        "\e[1;5C": end-of-line

        # Notifications
        set bell-style none
        set echo-control-characters off

        # link@, dir/...
        set visible-stats on

        # Don't show hidden files (unless .<tab>)
        set match-hidden-files off

        # Ignore case + treat - and _ as equivalent
        set completion-ignore-case on
        set completion-map-case on

        # Display all possible completions right away
        set show-all-if-ambiguous on
        set show-all-if-unmodified on

        # no (y or n) + no less
        set completion-query-items 200
        set page-completions off
        """
    ),
)

bashrc = MiniConfig(
    technology=Technology.BASH,
    path=Path('~/.bashrc'),
    content=dedent(
        r"""
        set -o notify

        shopt -s cdspell extglob nocaseglob nocasematch histappend

        # ls
        alias   l='command ls -FB   --color=auto'
        alias  ll='command ls -FBhl --color=auto'

        alias  la='command ls -FBA   --color=auto'
        alias lla='command ls -FBAhl --color=auto'

        alias  ld='command ls -FBd   --color=auto'
        alias lld='command ls -FBdhl --color=auto'

        alias  lm='command ls -FBtr   --color=auto'
        alias llm='command ls -FBhltr --color=auto'

        # cd
        alias -- -='cd - >/dev/null'

        alias 1='cd ..'
        alias 2='cd ../..'
        alias 3='cd ../../..'
        alias 4='cd ../../../..'
        alias 5='cd ../../../../..'
        alias 6='cd ../../../../../..'
        alias 7='cd ../../../../../../..'
        alias 8='cd ../../../../../../../..'
        alias 9='cd ../../../../../../../../..'

        # copy/move
        alias cp='cp -i'
        alias mv='mv -i'

        # vim
        if command -v vim >/dev/null 2>&1
        then
        export EDITOR=vim
        alias v=vim
        alias vd=vimdiff
        else
        alias v=vi
        fi

        # help
        export MANWIDTH=90
        alias m=man
        alias ?=type

        # grep
        alias g='grep -iE --color=auto --exclude="*~"'
        alias gr='grep -RiIE --color=auto --exclude="*~"'

        pg() {
        local fields=pid,stat,euser,egroup,start_time,cmd
        ps o "$fields" | head -n1
        ps axfww o "$fields" | \grep -v grep | \grep -iEB1 --color=auto "$@"
        }
        """
    ),
)

ksh_profile = MiniConfig(
    technology=Technology.KSH,
    path=Path('~/.profile'),
    content=dedent(
        r"""
        export HISTFILE=~/.sh_history
        export ENV=~/.kshrc
        """
    ),
)

kshrc = MiniConfig(
    technology=Technology.KSH,
    path=Path('~/.kshrc'),
    content=dedent(
        r"""
        # prompt
        PS1="[\u@$(hostname|perl -pe 's/\.[^.]+?(?:\.com|\.co\.uk)//') \w]\\$ "

        # ls
        alias l='ls -hF'
        alias ll='ls -lhF'
        alias la='ls -hFA'
        alias lla='ls -lhFA'
        alias ld='ls -hFd'
        alias lld='ls -lhFd'
        alias lm='ls -hFtr'
        alias llm='ls -lhFtr'

        # cd
        alias -- -='cd - >/dev/null'
        alias 1='cd ..'
        alias 2='cd ../..'
        alias 3='cd ../../..'
        alias 4='cd ../../../..'
        alias 5='cd ../../../../..'
        alias 6='cd ../../../../../..'
        alias 7='cd ../../../../../../..'
        alias 8='cd ../../../../../../../..'
        alias 9='cd ../../../../../../../../..'

        # copy/move
        alias cp='cp -i'
        alias mv='mv -i'

        # vim
        if command -v vim >/dev/null 2>&1
        then
        alias v=vim
        alias vd=vimdiff
        else
        alias v=vi
        fi

        # grep
        alias g='grep -iE'
        alias gr='grep -RiIE'

        # util
        alias m=man
        bind -m '^L'='^U'clear'^J^Y'
        """
    ),
)

miniconfigs = [vimrc_oneline, vimrc, inputrc, bashrc, ksh_profile, kshrc]
