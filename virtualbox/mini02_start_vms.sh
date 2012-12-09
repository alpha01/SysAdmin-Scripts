#!/bin/bash

VBoxHeadless -s OpenAFS2 &
sleep 15

VBoxHeadless -s OpenAFS &
sleep 15

VBoxHeadless -s dhcp &
sleep 15
