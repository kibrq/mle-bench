FROM mambaorg/micromamba:2.3.2-ubuntu20.04

USER root

ENV REQUIREMENTS=/tmp/requirements.txt

COPY environment/requirements.txt ${REQUIREMENTS}

ENV NONROOT_USER=nonroot
ENV NONROOT_HOME=/home/nonroot
ENV PRIVATE_ENV_NAME=mleb
ENV PRIVATE_PYTHON_VERSION=3.11
ENV EXECUTION_ENV_NAME=ml
ENV EXECUTION_PYTHON_VERSION=3.11

ARG INSTALL_HEAVY_DEPENDENCIES=no
ENV INSTALL_HEAVY_DEPENDENCIES=${INSTALL_HEAVY_DEPENDENCIES}

ENV MAMBA_ROOT_PREFIX=${NONROOT_HOME}/.micromamba/

ENV ROOT_MAMBA_ROOT_PREFIX=/opt/micromamba

RUN apt-get update && apt-get install -y \
    git \
	git-lfs \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN useradd -m -d "${NONROOT_HOME}" -s /bin/bash "${NONROOT_USER}" \
    && mkdir -p /private \
    && chmod 700 /private
    
# Create the private/tooling env and the training env.
RUN mkdir -p ${ROOT_MAMBA_ROOT_PREFIX} \
    && MAMBA_ROOT_PREFIX=${ROOT_MAMBA_ROOT_PREFIX} micromamba create -y -n "${PRIVATE_ENV_NAME}" python=${PRIVATE_PYTHON_VERSION} pip flask jupyter \
    && MAMBA_ROOT_PREFIX=${ROOT_MAMBA_ROOT_PREFIX} micromamba clean --all --yes

USER ${NONROOT_USER}

RUN mkdir -p ${MAMBA_ROOT_PREFIX} \
    && micromamba create -y -n ${EXECUTION_ENV_NAME} python=${EXECUTION_PYTHON_VERSION} pip \
    && micromamba clean --all --yes

# Install the ML runtime dependencies only into the training env.
RUN if [ "${INSTALL_HEAVY_DEPENDENCIES}" = "true" ]; then \
        micromamba run -n "${EXECUTION_ENV_NAME}" pip install --no-cache-dir -r "${REQUIREMENTS}" \
        && micromamba run -n "${EXECUTION_ENV_NAME}" pip install --no-cache-dir tensorflow[and-cuda]==2.17 \
        && micromamba run -n "${EXECUTION_ENV_NAME}" pip install --no-cache-dir torch==2.2.0 torchaudio==2.2.0 torchtext==0.17.0 torchvision==0.17.0 \
        && micromamba clean --all --yes; \
    fi


USER root

# Install benchmark code and grading dependencies into the private env.
COPY . /mlebench
WORKDIR /mlebench
RUN MAMBA_ROOT_PREFIX=${ROOT_MAMBA_ROOT_PREFIX} micromamba run -n "${PRIVATE_ENV_NAME}" pip install --no-cache-dir . && \
	MAMBA_ROOT_PREFIX=${ROOT_MAMBA_ROOT_PREFIX} micromamba clean --all --yes && \
	rm -r /mlebench

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=

# Copy over relevant files
COPY environment/grading_server.py /private/grading_server.py
COPY environment/instructions.txt /home/instructions.txt
COPY environment/instructions_obfuscated.txt /home/instructions_obfuscated.txt
COPY environment/validate_submission.sh /home/validate_submission.sh
COPY environment/entrypoint.sh /entrypoint.sh

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

WORKDIR /home

# IMPORTANT: This needs to run as root! Downstream Dockerfiles must not change the default USER for when the container starts.
# Entrypoint script is in charge of setting up the user environment and running the grading server
ENTRYPOINT ["/entrypoint.sh"]
