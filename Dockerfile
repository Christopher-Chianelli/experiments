FROM eclipse-temurin:21-jdk

RUN apt-get update
RUN apt-get install -y python3-pip maven

#ENV NVM_DIR /root/.nvm
#ENV NODE_VERSION 20
#RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
#    && . $NVM_DIR/nvm.sh \
#    && nvm use $NODE_VERSION \
#    && nvm install-latest-npm

RUN pip3 install --no-cache-dir python-dotenv["cli"] notebook\<7 jupyterlab jupyterlab_widgets jupyter_contrib_nbextensions ipywidgets

RUN jupyter contrib nbextension install --user
RUN jupyter nbextension enable --py widgetsnbextension
#RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.38 --minimize=False

USER root

# Set up the user environment

ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid $NB_UID \
    $NB_USER

COPY . $HOME
RUN chown -R $NB_UID $HOME

USER $NB_USER

# Download the kernel release
WORKDIR $HOME

RUN curl -sL https://github.com/allen-ball/ganymede/releases/download/v2.1.2.20230910/ganymede-2.1.2.20230910.jar -o ganymede.jar

# Install the kernel
RUN java -jar ganymede.jar -i --id=java --display-name=Java

# add requirements.txt, written this way to gracefully ignore a missing file
COPY . .
RUN ([ -f requirements.txt ] \
    && pip3 install --no-cache-dir -r requirements.txt) || true

# Launch the notebook server
CMD ["jupyter", "notebook", "--ip", "0.0.0.0", "--NotebookApp.show_banner=False"]