FROM debian:latest 
LABEL maintainer="Marc Schlienger <marc@schlienger.net>"

ENV DEBIAN_FRONTEND noninteractive
ENV PATH /opt/conda/bin:$PATH

# Common packages
RUN apt-get update && apt-get install -y \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    fontconfig \
    fonts-powerline \
    git \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    locales \
    locales-all \
    mercurial \
    mosh \
    openssh-server \
    python \
    python-dev \
    python3 \
    python3-dev \
    subversion \
    tmux \
    vim-nox \
    wget \
    zsh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Locale
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE:de
ENV LC_ALL de_DE.UTF-8

# User
RUN useradd -ms /usr/bin/zsh dev
RUN echo 'dev:screencast' | chpasswd

USER dev

# Zsh, vim and tmux
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
    && git clone https://github.com/marcschlienger/dotfiles.git /home/dev/dotfiles \
    && /home/dev/dotfiles/symlink.sh \
    && git clone https://github.com/VundleVim/Vundle.vim.git /home/dev/.vim/bundle/Vundle.vim \
    && vim +PluginInstall +qall \
    && /home/dev/.vim/bundle/YouCompleteMe/install.py --clang-completer

USER root

# Anaconda3
RUN wget --quiet https://repo.continuum.io/archive/Anaconda3-5.1.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /home/dev/.zshrc

# Tini
RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

# Fix the bug https://bugs.launchpad.net/ubuntu/+source/openssh/+bug/45234
RUN mkdir /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

EXPOSE 22/tcp 60001/udp
ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD ["/usr/sbin/sshd", "-D"]

